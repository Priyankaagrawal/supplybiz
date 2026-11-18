import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/subscriptions/vendor_subscriptions_controller.dart';
import 'package:supplybiz_mobile/features/subscriptions/vendor_subscriptions_pages.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../customers/customer_fixture.dart' show syntheticCustomerId;
import '../products/catalog_fixture.dart' show syntheticProductId;
import 'subscription_fixture.dart';

VendorSubscriptionsController subscriptionModel(
    SubscriptionFixture f, OnboardingDrafts store,
    {String owner = 'synthetic:vendor-subscriptions'}) {
  final c = NetworkClient(
      baseUrl: 'https://api.example.test',
      session: TestSession(),
      adapter: f,
      delay: (_) async {});
  return VendorSubscriptionsController(c, store, owner);
}

Map<String, dynamic> subscriptionInput() => {
      'vendorCustomerId': syntheticCustomerId,
      'productId': syntheticProductId,
      'qty': 1,
      'weekdays': [1, 2, 3, 4, 5, 6, 7],
      'startDate': '2026-11-18',
      'timeSlot': 'AM',
      'paymentMethod': 'CASH'
    };
Widget subscriptionApp(VendorSubscriptionsController model,
        {Widget? child, double scale = 1}) =>
    ProviderScope(
        overrides: [vendorSubscriptionsProvider.overrideWith((ref) => model)],
        child: MaterialApp(
            theme: sbLightTheme(const Locale('en')),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: child ?? const VendorSubscriptionsPage()));
Future<void> revealSubscription(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(finder, 250,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void closeSubscriptionModel(VendorSubscriptionsController m) {
  m.dispose();
  m.client.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'US-070 exact paise calendar estimate clips ranges and selected weekdays, including leap month',
      () {
    final result = subscriptionEstimate(
        BigInt.parse('9007199254740993'),
        3,
        {1, 2, 3, 4, 5, 6, 7},
        DateTime.utc(2028, 2, 27),
        DateTime.utc(2028, 2, 29),
        DateTime.utc(2028, 2));
    expect(result.daily, BigInt.parse('27021597764222979'));
    expect(result.monthly, BigInt.parse('81064793292668937'));
    expect(subscriptionParseDate('2026-02-30'), isNull);
    expect(subscriptionParseDate('2028-02-29'), isNotNull);
    expect(subscriptionAmount(BigInt.from(123456789)), '12,34,567.89');
    expect(subscriptionAmount(BigInt.from(-123456789)), '-12,34,567.89');
    expect(subscriptionAmount(BigInt.from(-1)), '-0.01');
  });
  test(
      'T-076 reads every page, searches, filters and restores offline only for the same account/environment',
      () async {
    final f = SubscriptionFixture(), store = MemoryDrafts();
    for (var i = 0; i < 101; i++) {
      f.rows.add(subscriptionJson(id: 'synthetic-$i', status: 'PAUSED'));
    }
    final m = subscriptionModel(f, store);
    addTearDown(() => closeSubscriptionModel(m));
    await m.load();
    expect(m.rows, hasLength(102));
    expect(m.visible, hasLength(20));
    m.query('Cow', 'PAUSED');
    expect(m.filtered, hasLength(101));
    f.offline = true;
    final restored = subscriptionModel(f, store);
    addTearDown(() => closeSubscriptionModel(restored));
    await restored.load();
    expect(restored.rows, hasLength(102));
    expect(restored.cached, isTrue);
    expect(restored.canEdit, isFalse);
    final other =
        subscriptionModel(f, store, owner: 'other:vendor-subscriptions');
    addTearDown(() => closeSubscriptionModel(other));
    await other.load();
    expect(other.rows, isEmpty);
  });
  test(
      'US-070 committed create with lost response restores exact payload/key and commits once',
      () async {
    final f = SubscriptionFixture(),
        store = MemoryDrafts(),
        m = subscriptionModel(f, MemoryDrafts());
    // The actual request store survives controller recreation.
    closeSubscriptionModel(m);
    final first = subscriptionModel(f, store);
    await first.load();
    f.loseResponse = true;
    await first.submit('CREATE', subscriptionInput());
    expect(
        jsonDecode(f.writes.single.data as String)['startDate'], '2026-11-18');
    expect(first.pending, isNotNull);
    final saved = jsonEncode(first.pending);
    final key = f.writes.single.headers['Idempotency-Key'];
    closeSubscriptionModel(first);
    final next = subscriptionModel(f, store);
    addTearDown(() => closeSubscriptionModel(next));
    await next.load();
    expect(jsonEncode(next.pending), saved);
    expect(next.canEdit, isFalse);
    await next.retry();
    expect(next.pending, isNull);
    expect(f.commits, 1);
    expect(f.writes.last.headers['Idempotency-Key'], key);
  });
  test(
      'T-076 disk failure before send blocks HTTP; acknowledgement failure preserves committed retry',
      () async {
    final f = SubscriptionFixture(),
        store = MemoryDrafts(),
        m = subscriptionModel(f, MemoryDrafts());
    closeSubscriptionModel(m);
    final model = subscriptionModel(f, store);
    addTearDown(() => closeSubscriptionModel(model));
    await model.load();
    store.fail = true;
    await model.submit('CREATE', subscriptionInput());
    expect(f.writes, isEmpty);
    expect(model.pending, isNotNull);
    store.fail = false;
    f.afterCommit = () => store.fail = true;
    await model.retry();
    expect(f.commits, 1);
    expect(model.pending, isNotNull);
    store.fail = false;
    f.afterCommit = null;
    await model.retry();
    expect(f.commits, 1);
    expect(model.pending, isNull);
  });
  test(
      'US-072 generated mutations freeze version/date/reason; conflict clears pending and requires fresh review',
      () async {
    final f = SubscriptionFixture(),
        m = subscriptionModel(SubscriptionFixture(), MemoryDrafts());
    closeSubscriptionModel(m);
    final model = subscriptionModel(f, MemoryDrafts());
    addTearDown(() => closeSubscriptionModel(model));
    await model.load();
    for (final action in [
      'EDIT',
      'PAUSE',
      'SKIP',
      'CANCEL',
      'RESUME',
      'APPROVE',
      'REJECT'
    ]) {
      final body = <String, dynamic>{
        'version': 1,
        if (action == 'EDIT') 'qty': 2,
        if (action == 'PAUSE') 'fromDate': '2026-11-18',
        if (action == 'SKIP') 'date': '2026-11-18',
        if (action == 'REJECT') 'reason': 'Synthetic reason'
      };
      await model.submit(action, body, id: subscriptionId);
      expect(model.failure, isNull);
      expect(jsonDecode(f.writes.last.data as String), body);
      expect(f.writes.last.headers['Idempotency-Key'], isNotEmpty);
    }
    f.rejection = 409;
    await model.submit('CANCEL', {'version': 1}, id: subscriptionId);
    expect(model.failure, isA<ConflictFailure>());
    expect(model.pending, isNull);
    expect(model.canWrite, isFalse);
    f.rejection = null;
    await model.load();
    expect(model.canWrite, isTrue);
  });
  test(
      'US-073 typed null clears and settings retry expiry never mint a replacement key',
      () async {
    final f = SubscriptionFixture(),
        store = MemoryDrafts(),
        m = subscriptionModel(f, MemoryDrafts());
    closeSubscriptionModel(m);
    final model = subscriptionModel(f, store);
    addTearDown(() => closeSubscriptionModel(model));
    await model.load();
    await model.submit('SETTINGS', {
      'version': 1,
      'clearDeliveryWindow': true,
      'clearMaxDailyOrders': true,
      'clearDailyMilkCapacity': true
    });
    expect(model.failure, isNull);
    expect(jsonDecode(f.writes.last.data as String)['clearDailyMilkCapacity'],
        true);
    f.loseResponse = true;
    await model
        .submit('SETTINGS', {'version': 2, 'pauseAllSubscriptions': true});
    final count = f.writes.length;
    model.pending!['savedAt'] = '2020-01-01T00:00:00Z';
    await model.retry();
    expect(f.writes, hasLength(count));
    expect(model.retryExpired, isTrue);
    await model.discardExpired();
    expect(model.pending, isNull);
    expect(model.settings!.pauseAllSubscriptions, isTrue);
  });
  test(
      'T-076 permission loss clears contacts/history/pending; disposed reads cannot republish',
      () async {
    final f = SubscriptionFixture(),
        store = MemoryDrafts(),
        m = subscriptionModel(f, MemoryDrafts());
    closeSubscriptionModel(m);
    final model = subscriptionModel(f, store);
    await model.load();
    f.denial = 403;
    await model.load();
    expect(model.rows, isEmpty);
    expect(model.customers, isEmpty);
    expect(await store.read(model.owner), isEmpty);
    f.denial = null;
    f.gate = Completer<void>();
    final active = model.load();
    await Future<void>.delayed(Duration.zero);
    closeSubscriptionModel(model);
    f.gate!.complete();
    await active;
    expect(model.rows, isEmpty);
  });
  testWidgets(
      'US-073 200% settings uses server plan locks and retains reducing controls',
      (tester) async {
    final f = SubscriptionFixture()..controls['canEditSubscriptions'] = false,
        m = subscriptionModel(SubscriptionFixture(), MemoryDrafts());
    closeSubscriptionModel(m);
    final model = subscriptionModel(f, MemoryDrafts());
    await tester.runAsync(model.load);
    expect(model.failure, isNull);
    await tester.pumpWidget(subscriptionApp(model,
        child: const VendorSubscriptionSettingsPage(), scale: 2));
    await tester.pumpAndSettle();
    final auto = find.widgetWithText(
        SwitchListTile, 'Automatically accept subscription orders');
    await revealSubscription(tester, auto);
    expect(tester.widget<SwitchListTile>(auto).onChanged, isNull);
    final pause =
        find.widgetWithText(SwitchListTile, 'Pause all subscriptions');
    await revealSubscription(tester, pause);
    expect(tester.widget<SwitchListTile>(pause).onChanged, isNotNull);
    await tester.tap(pause);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(f.writes, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.client.close();
  });
  testWidgets('US-070 editor rejects empty required data at 200%',
      (tester) async {
    final f = SubscriptionFixture(),
        m = subscriptionModel(SubscriptionFixture(), MemoryDrafts());
    closeSubscriptionModel(m);
    final model = subscriptionModel(f, MemoryDrafts());
    await tester.runAsync(model.load);
    expect(model.failure, isNull);
    await tester.pumpWidget(subscriptionApp(model,
        child: VendorSubscriptionEditor(model: model), scale: 2));
    await tester.pumpAndSettle();
    await revealSubscription(tester, find.widgetWithText(SbButton, 'Save'));
    await tester.tap(find.widgetWithText(SbButton, 'Save'));
    await tester.pumpAndSettle();
    expect(f.writes, isEmpty);
    expect(find.textContaining('Check the required selection'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
    model.client.close();
  });
  testWidgets(
      'US-070 whole-pack stepper updates the exact calendar estimate at 200%',
      (tester) async {
    final model = subscriptionModel(SubscriptionFixture(), MemoryDrafts());
    await tester.runAsync(model.load);
    expect(model.failure, isNull);
    await tester.pumpWidget(subscriptionApp(model,
        child: VendorSubscriptionEditor(model: model, row: model.rows.single),
        scale: 2));
    await tester.pumpAndSettle();
    final more = find.byTooltip('Increase packs per delivery');
    await revealSubscription(tester, more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    await revealSubscription(tester, find.text('Per delivery: ₹110.00'));
    expect(find.text('Estimated 2026-11: ₹1,430.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
    model.client.close();
  });
}
