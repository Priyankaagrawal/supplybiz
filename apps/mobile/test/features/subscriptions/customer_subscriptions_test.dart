import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/subscriptions/customer_subscriptions_controller.dart';
import 'package:supplybiz_mobile/features/subscriptions/customer_subscriptions_pages.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../products/catalog_fixture.dart' show syntheticProductId;
import '../addresses/address_fixture.dart' show addressId;
import '../addresses/addresses_test.dart' show reveal;
import 'subscription_fixture.dart' show subscriptionId, subscriptionJson;
import 'customer_subscription_fixture.dart';

CustomerSubscriptionsController customerSubscriptionModel(
        CustomerSubscriptionFixture f, OnboardingDrafts store,
        {String owner = 'synthetic:customer-subscriptions'}) =>
    CustomerSubscriptionsController(
        NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: f,
            delay: (_) async {}),
        store,
        owner);
Map<String, dynamic> customerSubscriptionInput() => {
      'vendorId': syntheticProductId,
      'addressId': addressId,
      'productId': syntheticProductId,
      'qty': 1,
      'weekdays': [1, 2, 3, 4, 5, 6, 7],
      'timeSlot': 'AM',
      'startDate': '2026-11-18',
      'paymentMethod': 'CASH'
    };
Widget customerSubscriptionApp(CustomerSubscriptionsController m,
        {Widget? child, double scale = 1}) =>
    ProviderScope(
        overrides: [customerSubscriptionsProvider.overrideWith((ref) => m)],
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
            home: child ?? const CustomerSubscriptionsPage()));
void closeCustomerSubscription(CustomerSubscriptionsController m) {
  m.dispose();
  m.client.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'T-078 reads all pages, prepares address-owned plans and cash-only optional UPI',
      () async {
    final f = CustomerSubscriptionFixture(),
        m = customerSubscriptionModel(f, MemoryDrafts());
    addTearDown(() => closeCustomerSubscription(m));
    f.rows.addAll([
      for (var i = 1; i <= 51; i++)
        subscriptionJson(
            id: '${i.toString().padLeft(8, '0')}-3333-4333-8333-333333333333')
    ]);
    await m.load();
    expect(m.rows, hasLength(52));
    expect(m.businessDate!.toIso8601String().substring(0, 10), '2026-11-17');
    await m.prepare(syntheticProductId);
    expect(m.failure, isNull);
    expect(m.canCreate, isTrue);
    expect(m.addressId, addressId);
    expect(m.plans!.items, hasLength(2));
    expect(m.upiAvailable, isFalse);
    f.published = true;
    await m.prepare(syntheticProductId);
    expect(m.upiAvailable, isTrue);
  });
  test(
      'T-078 lost response preserves exact key/body across recreation and account isolation; no automatic retry',
      () async {
    final f = CustomerSubscriptionFixture(),
        store = MemoryDrafts(),
        first = customerSubscriptionModel(f, store);
    await first.load();
    await first.prepare(syntheticProductId);
    f.loseResponse = true;
    await first.submit('CREATE', customerSubscriptionInput());
    expect(first.pending, isNotNull);
    expect(
        jsonDecode(f.writes.first.data as String)['startDate'], '2026-11-18');
    final saved = jsonEncode(first.pending), key = first.pending!['key'];
    closeCustomerSubscription(first);
    final restored = customerSubscriptionModel(f, store);
    addTearDown(() => closeCustomerSubscription(restored));
    await restored.load();
    expect(jsonEncode(restored.pending), saved);
    expect(restored.canWrite, isFalse);
    expect(f.writes, hasLength(1));
    await restored.retry();
    expect(restored.pending, isNull);
    expect(f.commits, 1);
    expect(f.writes.last.headers['Idempotency-Key'], key);
    final other = customerSubscriptionModel(f, store,
        owner: 'different:customer-subscriptions');
    addTearDown(() => closeCustomerSubscription(other));
    f.offline = true;
    await other.load();
    expect(other.rows, isEmpty);
    expect(other.pending, isNull);
  });
  test(
      'T-078 cannot send before durable save; cached data never authorizes mutation; auth denial clears data',
      () async {
    final f = CustomerSubscriptionFixture(),
        store = MemoryDrafts(),
        m = customerSubscriptionModel(f, store);
    addTearDown(() => closeCustomerSubscription(m));
    await m.load();
    await m.prepare(syntheticProductId);
    store.fail = true;
    await m.submit('CREATE', customerSubscriptionInput());
    expect(f.writes, isEmpty);
    expect(m.pending, isNotNull);
    store.fail = false;
    await m.retry();
    expect(f.commits, 1);
    f.offline = true;
    await m.load();
    await m.submit('CANCEL', {'version': 1}, id: subscriptionId);
    expect(f.commits, 1);
    expect(m.canWrite, isFalse);
    f.offline = false;
    f.readDenial = 403;
    await m.load();
    expect(m.rows, isEmpty);
    expect(m.statement, isNull);
    expect(m.pending, isNull);
    expect(store.rows[m.owner], isEmpty);
  });
  test(
      'T-078 versioned customer actions keep calendar fields and cutoff/conflict errors require refreshed review',
      () async {
    final f = CustomerSubscriptionFixture(),
        m = customerSubscriptionModel(f, MemoryDrafts());
    addTearDown(() => closeCustomerSubscription(m));
    await m.load();
    for (final action in ['EDIT', 'PAUSE', 'RESUME', 'SKIP', 'CANCEL']) {
      final body = {
        'version': 1,
        if (action == 'EDIT') 'qty': 2,
        if (action == 'PAUSE') 'fromDate': '2026-11-18',
        if (action == 'PAUSE') 'toDate': '2026-11-21',
        if (action == 'SKIP') 'date': '2026-11-18'
      };
      await m.submit(action, body, id: subscriptionId);
      expect(m.failure, isNull);
      expect(jsonDecode(f.writes.last.data as String), body);
    }
    f.rejection = 422;
    f.rejectCode = 'PAST_CUTOFF';
    await m.submit('SKIP', {'version': 1, 'date': '2026-11-18'},
        id: subscriptionId);
    expect(m.failure!.code, 'PAST_CUTOFF');
    expect(m.pending, isNull);
    expect(m.canWrite, isFalse);
    f.rejection = null;
    await m.load();
    f.rejection = 409;
    await m.submit('CANCEL', {'version': 1}, id: subscriptionId);
    expect(m.pending, isNull);
    expect(m.canWrite, isFalse);
  });
  test(
      'T-078 monthly statement preserves exact ledger strings and paginates delivered dates',
      () async {
    final f = CustomerSubscriptionFixture()..deliveredTotal = 51,
        m = customerSubscriptionModel(f, MemoryDrafts());
    addTearDown(() => closeCustomerSubscription(m));
    await m.load(id: subscriptionId);
    await m.readStatement(subscriptionId, '2026-11');
    expect(m.statement!.items, hasLength(50));
    expect(m.statement!.ledger.duePaise, '9007199254740993');
    await m.readStatement(subscriptionId, '2026-11', more: true);
    expect(m.statement!.items, hasLength(51));
    expect(f.calls.last.queryParameters['offset'], 50);
  });
  testWidgets('T-078 plans require a server plan selection before continuing',
      (tester) async {
    final f = CustomerSubscriptionFixture(),
        m = customerSubscriptionModel(f, MemoryDrafts());
    await tester.pumpWidget(customerSubscriptionApp(m,
        child:
            const CustomerSubscriptionPlansPage(vendorId: syntheticProductId)));
    await tester.runAsync(() async {
      for (var i = 0; i < 100 && (m.busy || m.plans == null); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(m.failure, isNull);
    expect(
        tester
            .widget<SbButton>(find.widgetWithText(SbButton, 'Continue'))
            .onPressed,
        isNull);
    expect(find.text('Most popular'), findsNothing);
    await reveal(tester, find.byType(RadioListTile<String>).first);
    await tester.tap(find.byType(RadioListTile<String>).first);
    await tester.pumpAndSettle();
    await reveal(tester, find.widgetWithText(SbButton, 'Continue'));
    expect(
        tester
            .widget<SbButton>(find.widgetWithText(SbButton, 'Continue'))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'T-078 plans use server prices, no invented popularity and cash-only setup at 200%',
      (tester) async {
    final f = CustomerSubscriptionFixture(),
        m = customerSubscriptionModel(f, MemoryDrafts());
    await tester.runAsync(() async {
      await m.load();
      await m.prepare(syntheticProductId);
    });
    await tester.pumpWidget(customerSubscriptionApp(m,
        child: CustomerSubscriptionEditor(model: m, plan: m.plans!.items.first),
        scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('Most popular'), findsNothing);
    expect(find.textContaining('Cash is the only'), findsOneWidget);
    await reveal(
        tester,
        find.widgetWithText(
            DropdownButtonFormField<String>, 'Payment preference'));
    await tester.tap(find.widgetWithText(
        DropdownButtonFormField<String>, 'Payment preference'));
    await tester.pumpAndSettle();
    expect(find.text('UPI'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'T-078 cancel requires explicit confirmation and statement labels shared account totals',
      (tester) async {
    final f = CustomerSubscriptionFixture(),
        m = customerSubscriptionModel(f, MemoryDrafts());
    await tester.runAsync(() => m.load(id: subscriptionId));
    await tester.pumpWidget(customerSubscriptionApp(m,
        child: const CustomerSubscriptionsPage(id: subscriptionId)));
    await tester.pumpAndSettle();
    await reveal(tester, find.widgetWithText(SbButton, 'Cancel subscription'));
    await tester.tap(find.widgetWithText(SbButton, 'Cancel subscription'));
    await tester.pumpAndSettle();
    expect(f.writes, isEmpty);
    expect(find.textContaining('Stop future subscription'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(f.writes, isEmpty);
    await reveal(tester, find.widgetWithText(SbButton, 'Monthly statement'));
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(SbButton, 'Monthly statement'));
      for (var i = 0; i < 100 && m.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(m.statement, isNotNull);
    await reveal(tester, find.textContaining('Shared vendor account:'));
    expect(find.textContaining('Shared vendor account:'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
