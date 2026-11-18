import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/router/guards.dart';
import 'package:supplybiz_mobile/features/availability/availability_controller.dart';
import 'package:supplybiz_mobile/features/availability/availability_page.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/addresses_test.dart' show reveal;
import 'availability_fixture.dart';

AvailabilityController availabilityModel(
        AvailabilityFixture f, OnboardingDrafts store,
        {String owner = 'synthetic:vendor-availability'}) =>
    AvailabilityController(
        NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: f,
            delay: (_) async {}),
        store,
        owner);
Widget availabilityApp(AvailabilityController m, {double scale = 1}) =>
    ProviderScope(
        overrides: [availabilityProvider.overrideWith((ref) => m)],
        child: MaterialApp(
            theme: sbLightTheme(const Locale('en')),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...SbLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: const AvailabilityPage()));
void closeAvailability(AvailabilityController m) {
  m.dispose();
  m.client.close();
}

Future<void> settleAvailability(
        WidgetTester tester, AvailabilityController m) =>
    tester.runAsync(() async {
      for (var i = 0; i < 100 && m.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'T-077 server dates, complete holiday pagination, impact preview and versioned exact PATCH',
      () async {
    final f = AvailabilityFixture(), m = availabilityModel(f, MemoryDrafts());
    addTearDown(() => closeAvailability(m));
    f.rows.addAll([
      for (var i = 1; i <= 51; i++)
        availabilityHoliday(
            id: '${i.toString().padLeft(8, '0')}-2222-4222-8222-222222222222')
    ]);
    await m.load();
    expect(m.holidays, hasLength(52));
    expect(m.visible, hasLength(20));
    m.more();
    expect(m.visible, hasLength(40));
    expect((await m.impact(date: '2026-11-19'))!.affectedOrders, 3);
    expect(f.calls.last.queryParameters['date'], '2026-11-19');
    expect(f.writes, isEmpty);
    await m.submit('PATCH', {'version': 1, 'deliveryPaused': true});
    expect(m.failure, isNull);
    expect(m.state!.deliveryPaused, isTrue);
    expect(m.cancelledOrders, 3);
    expect(jsonDecode(f.writes.single.data as String),
        {'version': 1, 'deliveryPaused': true});
    expect(m.future(m.holidays.first), isTrue);
  });
  test(
      'T-077 holiday uses exact calendar string and reason, DELETE uses owned id and key without body',
      () async {
    final f = AvailabilityFixture()..rows.clear(),
        m = availabilityModel(f, MemoryDrafts());
    addTearDown(() => closeAvailability(m));
    await m.load();
    await m.submit(
        'HOLIDAY', {'date': '2026-11-19', 'reason': 'Synthetic holiday'});
    expect(jsonDecode(f.writes.single.data as String),
        {'date': '2026-11-19', 'reason': 'Synthetic holiday'});
    expect(m.holidays, hasLength(1));
    await m.submit('DELETE', {}, id: availabilityHolidayId);
    expect(m.holidays, isEmpty);
    expect(m.completed, isTrue);
    expect(f.writes.last.method, 'DELETE');
    expect(f.writes.last.uri.path,
        '/api/v1/vendor/holidays/$availabilityHolidayId');
    expect(f.writes.last.data, isNull);
    expect(f.writes.last.headers['Idempotency-Key'], isNotEmpty);
  });
  test(
      'T-077 lost response restores exact body/key across recreation; load never resends and accounts stay isolated',
      () async {
    final f = AvailabilityFixture(),
        store = MemoryDrafts(),
        first = availabilityModel(f, store);
    await first.load();
    f.loseResponse = true;
    await first.submit('PATCH', {'version': 1, 'deliveryPaused': true});
    final saved = jsonEncode(first.pending), key = first.pending!['key'];
    expect(first.pending, isNotNull);
    closeAvailability(first);
    final restored = availabilityModel(f, store);
    addTearDown(() => closeAvailability(restored));
    await restored.load();
    expect(jsonEncode(restored.pending), saved);
    expect(restored.canWrite, isFalse);
    expect(f.writes, hasLength(1));
    await restored.retry();
    expect(f.commits, 1);
    expect(f.writes.last.headers['Idempotency-Key'], key);
    expect(restored.pending, isNull);
    f.offline = true;
    final other =
        availabilityModel(f, store, owner: 'different:vendor-availability');
    addTearDown(() => closeAvailability(other));
    await other.load();
    expect(other.state, isNull);
    expect(other.holidays, isEmpty);
    expect(other.pending, isNull);
  });
  test(
      'T-077 failed local save sends nothing; cached snapshots cannot authorize new writes; conflict needs refresh',
      () async {
    final f = AvailabilityFixture(),
        store = MemoryDrafts(),
        m = availabilityModel(f, store);
    addTearDown(() => closeAvailability(m));
    await m.load();
    store.fail = true;
    await m.submit('PATCH', {'version': 1, 'acceptingToday': false});
    expect(f.writes, isEmpty);
    expect(m.pending, isNotNull);
    store.fail = false;
    await m.retry();
    expect(f.commits, 1);
    f.offline = true;
    await m.load();
    expect(m.stale, isTrue);
    await m.submit('PATCH', {'version': 2, 'deliveryPaused': true});
    expect(f.commits, 1);
    expect(await m.impact(), isNull);
    f.offline = false;
    await m.load();
    f.rejection = 409;
    await m.submit('PATCH', {'version': 1, 'deliveryPaused': true});
    expect(m.failure!.code, 'VERSION_CONFLICT');
    expect(m.pending, isNull);
    expect(m.canWrite, isFalse);
  });
  test(
      'T-077 expired plan keeps reducing controls but cannot resume/delete; today holiday stays undeletable',
      () async {
    final f = AvailabilityFixture()..state['canResume'] = false,
        m = availabilityModel(f, MemoryDrafts());
    addTearDown(() => closeAvailability(m));
    f.rows.add(availabilityHoliday(
        date: '2026-11-18', id: '22222222-2222-4222-8222-222222222222'));
    await m.load();
    expect(m.canReduce, isTrue);
    expect(m.canResume, isFalse);
    expect(m.future(m.holidays.last), isFalse);
    f.denial = 403;
    await m.load();
    expect(m.state, isNull);
    expect(m.holidays, isEmpty);
    expect(m.pending, isNull);
  });
  test(
      'T-077 acknowledgement-write failure keeps the same key; deleted holiday replay remains recoverable',
      () async {
    final f = AvailabilityFixture(),
        store = MemoryDrafts(),
        m = availabilityModel(f, store);
    addTearDown(() => closeAvailability(m));
    await m.load();
    f.afterCommit = () => store.fail = true;
    await m.submit('DELETE', {}, id: availabilityHolidayId);
    expect(m.pending, isNotNull);
    expect(f.commits, 1);
    final key = m.pending!['key'];
    store.fail = false;
    f.afterCommit = null;
    await m.load();
    expect(m.holidays, isEmpty);
    expect(m.pending, isNotNull);
    await m.retry();
    expect(m.pending, isNull);
    expect(f.commits, 1);
    expect(f.writes.last.headers['Idempotency-Key'], key);
  });
  test(
      'T-077 disposal and role denial cannot republish cached state or send a change',
      () async {
    final f = AvailabilityFixture(),
        store = MemoryDrafts(),
        m = availabilityModel(f, store);
    await m.load();
    f.gate = Completer<void>();
    final active = m.load();
    await Future<void>.delayed(Duration.zero);
    closeAvailability(m);
    f.gate!.complete();
    await active;
    expect(f.writes, isEmpty);
    expect(m.canWrite, isFalse);
    const vendor = RouteAccess(
            signedIn: true,
            activeRole: AppRole.vendor,
            onboardingComplete: true),
        customer = RouteAccess(signedIn: true, activeRole: AppRole.customer);
    expect(guardRedirect(vendor, '/vendor/availability'), isNull);
    expect(
        guardRedirect(customer, '/vendor/availability'), '/common/switch-role');
    expect(
        guardRedirect(const RouteAccess(), '/vendor/availability'), '/login');
  });
  testWidgets(
      'T-077 pause shows impact before commit and cancel leaves server unchanged at 200%',
      (tester) async {
    final f = AvailabilityFixture(), m = availabilityModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    await tester.pumpWidget(availabilityApp(m, scale: 2));
    await settleAvailability(tester, m);
    await tester.pumpAndSettle();
    await reveal(tester, find.widgetWithText(SbButton, 'Pause deliveries'));
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(SbButton, 'Pause deliveries'));
      for (var i = 0; i < 100 && m.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('3 existing orders will be cancelled.'),
        findsOneWidget);
    expect(f.writes, isEmpty);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(f.writes, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'T-077 date picker starts from server IST date and keeps the form alive on return',
      (tester) async {
    final f = AvailabilityFixture(), m = availabilityModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    await tester.pumpWidget(availabilityApp(m));
    await settleAvailability(tester, m);
    await tester.pumpAndSettle();
    await reveal(tester, find.widgetWithText(SbButton, 'Mark holiday'));
    await tester.tap(find.widgetWithText(SbButton, 'Mark holiday'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextFormField, 'Holiday date'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<DatePickerDialog>(find.byType(DatePickerDialog))
            .firstDate,
        DateTime(2026, 11, 18));
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Reason'),
        'Synthetic picker return');
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(f.writes, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'T-077 holiday reason validated; preview count requires second confirmation before write',
      (tester) async {
    final f = AvailabilityFixture(), m = availabilityModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    await tester.pumpWidget(availabilityApp(m));
    await settleAvailability(tester, m);
    await tester.pumpAndSettle();
    await reveal(tester, find.widgetWithText(SbButton, 'Mark holiday'));
    await tester.tap(find.widgetWithText(SbButton, 'Mark holiday'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(f.writes, isEmpty);
    expect(find.textContaining('Check the required'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Reason'), 'Synthetic holiday');
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, 'Continue'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('3 existing orders'), findsOneWidget);
    expect(f.writes, isEmpty);
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
      for (var i = 0; i < 100 && m.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(f.commits, 1);
    expect(jsonDecode(f.writes.single.data as String)['date'], '2026-11-18');
    expect(m.cancelledOrders, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'T-077 expired state disables enabling/deletion and keeps pause; today deletion disabled',
      (tester) async {
    final f = AvailabilityFixture()
          ..state['canResume'] = false
          ..state['acceptingToday'] = false,
        m = availabilityModel(f, MemoryDrafts());
    f.rows.insert(0, availabilityHoliday(date: '2026-11-18'));
    await tester.runAsync(m.load);
    await tester.pumpWidget(availabilityApp(m));
    await settleAvailability(tester, m);
    await tester.pumpAndSettle();
    await reveal(tester, find.byType(SwitchListTile));
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull);
    await reveal(tester, find.widgetWithText(SbButton, 'Pause deliveries'));
    expect(
        tester
            .widget<SbButton>(find.widgetWithText(SbButton, 'Pause deliveries'))
            .onPressed,
        isNotNull);
    await reveal(tester, find.widgetWithText(SbButton, 'Delete holiday').first);
    expect(
        tester
            .widget<SbButton>(
                find.widgetWithText(SbButton, 'Delete holiday').first)
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.client.close();
  });
}
