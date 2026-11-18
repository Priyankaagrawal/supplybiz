import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/sales/sales_controller.dart';
import 'package:supplybiz_mobile/features/sales/sales_page.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../products/catalog_fixture.dart' show syntheticProductId, productJson;
import '../customers/customer_fixture.dart'
    show syntheticCustomerId, customerJson;
import '../addresses/addresses_test.dart' show reveal;
import 'sales_fixture.dart';

SalesController salesModel(SalesFixture f, OnboardingDrafts store,
    {String owner = 'synthetic:sales',
    Future<void> Function()? schedule,
    bool coordinated = false}) {
  final client = NetworkClient(
      baseUrl: 'https://api.example.test',
      session: TestSession(),
      adapter: f,
      delay: (_) async {});
  return SalesController(client.dio, store, owner,
      schedule: schedule, coordinated: coordinated);
}

void closeSales(SalesController m) {
  m.dispose();
  m.dio.close(force: true);
}

Widget salesApp(SalesController m, {double scale = 1}) => ProviderScope(
    overrides: [salesProvider.overrideWith((ref) => m)],
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
        home: const SalesPage()));
Future<void> settleSales(WidgetTester tester, SalesController m) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 100 && m.busy; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'TC-058 exact currency rejects decimals/overflow/negative and never rounds',
      () {
    expect(saleRupees('90071992547409.93').toString(), '9007199254740993');
    expect(saleDecimal(saleMax), '92233720368547758.07');
    expect(saleRupees('92233720368547758.08'), isNull);
    for (final invalid in ['-1', 'NaN', '1.005', '1e3', '01', '']) {
      expect(saleRupees(invalid), isNull);
    }
    expect(saleRupees('0.01'), BigInt.one);
  });
  test(
      'TC-055/056 walk-in validates full payment and stock; acknowledgement is one receipt and stock delta',
      () async {
    final f = SalesFixture(), m = salesModel(f, MemoryDrafts());
    addTearDown(() => closeSales(m));
    await m.load();
    expect(
        await m.enqueue('partial', saleItems(),
            paidPaise: '100', method: 'CASH'),
        isFalse);
    expect(m.failure!.code, 'WALKIN_MUST_BE_PAID');
    expect(f.commits, 0);
    expect(
        await m.enqueue('large', saleItems(qty: 13),
            paidPaise: '78130', method: 'CASH'),
        isFalse);
    expect(m.failure!.code, 'INSUFFICIENT_STOCK');
    expect(
        await m.enqueue('one', saleItems(), paidPaise: '6010', method: 'CASH'),
        isTrue);
    expect(f.commits, 1);
    expect(m.queue, isEmpty);
    expect(m.receipt('one')!.saleNo, 'SALE1');
    expect(m.available(syntheticProductId), 11);
    await m.enqueue('one', saleItems(), paidPaise: '6010', method: 'CASH');
    expect(f.commits, 1);
  });
  test(
      'TC-057 customer partial sale freezes explicit rate/amount and zero payment uses Khata',
      () async {
    final f = SalesFixture(), m = salesModel(f, MemoryDrafts());
    addTearDown(() => closeSales(m));
    await m.load();
    await m.enqueue('customer', saleItems(qty: 2, rate: '6500'),
        customerId: syntheticCustomerId, paidPaise: '10000', method: 'UPI');
    expect(m.receipt('customer')!.balancePaise, '3000');
    final body = jsonDecode(f.writes.single.data as String);
    expect(body['vendorCustomerId'], syntheticCustomerId);
    expect(body['items'][0]['ratePaise'], '6500');
    expect(body['clientCreatedAt'], isA<String>());
    await m.enqueue('unpaid', saleItems(),
        customerId: syntheticCustomerId, paidPaise: '0', method: 'OTHER');
    expect(m.receipt('unpaid')!.balancePaise, '6010');
  });
  test(
      'TC-059 offline durable FIFO reserves stock, schedules before persistence and freezes key/body after recreation',
      () async {
    final f = SalesFixture(), store = MemoryDrafts();
    var scheduled = 0;
    final m = salesModel(f, store, schedule: () async {
      scheduled++;
    });
    await m.load();
    f.offline = true;
    await m.enqueue('first', saleItems(qty: 2),
        paidPaise: '12020', method: 'CASH');
    final saved = jsonEncode(m.queue.first.body);
    expect(m.available(syntheticProductId), 10);
    expect(scheduled, 1);
    await m.enqueue('second', saleItems(qty: 3),
        paidPaise: '18030', method: 'CASH');
    expect(m.available(syntheticProductId), 7);
    expect(m.receipts, isEmpty);
    expect(m.canDiscard(m.queue.first), isFalse);
    closeSales(m);
    final next = salesModel(f, store);
    addTearDown(() => closeSales(next));
    await next.load();
    expect(next.queue, hasLength(2));
    expect(jsonEncode(next.queue.first.body), saved);
    f.offline = false;
    await next.flush(retry: true);
    expect(f.commits, 2);
    expect(next.queue, isEmpty);
    expect(next.available(syntheticProductId), 7);
    expect(
        f.writes
            .where((r) => r.headers['Idempotency-Key'] == 'first')
            .map((r) => r.data)
            .toSet(),
        hasLength(1));
    final other = salesModel(f, store, owner: 'other:sales');
    addTearDown(() => closeSales(other));
    f.offline = true;
    await other.load();
    expect(other.products, isEmpty);
    expect(other.queue, isEmpty);
    expect(other.receipts, isEmpty);
  });
  test(
      'TC-059 committed response loss and failed local acknowledgement replay the original key exactly once',
      () async {
    final f = SalesFixture(), store = MemoryDrafts();
    var m = salesModel(f, store);
    await m.load();
    f.loseResponse = true;
    await m.enqueue('lost', saleItems(), paidPaise: '6010', method: 'CASH');
    expect(f.commits, 1);
    expect(m.receipts, isEmpty);
    closeSales(m);
    m = salesModel(f, store);
    await m.flush(retry: true);
    expect(f.commits, 1);
    expect(m.queue, isEmpty);
    expect(m.receipt('lost'), isNotNull);
    f.afterCommit = () => store.fail = true;
    await m.enqueue('disk', saleItems(), paidPaise: '6010', method: 'CASH');
    expect(m.canCreate, isFalse);
    closeSales(m);
    store.fail = false;
    f.afterCommit = null;
    m = salesModel(f, store);
    addTearDown(() => closeSales(m));
    await m.flush(retry: true);
    expect(f.commits, 2);
    expect(m.queue, isEmpty);
    expect(m.available(syntheticProductId), 10);
  });
  test(
      'TC-059 storage failure sends nothing, definitive conflict rolls back reservation, uncertain sends cannot discard',
      () async {
    final f = SalesFixture(), store = MemoryDrafts(), m = salesModel(f, store);
    addTearDown(() => closeSales(m));
    await m.load();
    store.fail = true;
    expect(
        await m.enqueue('fail', saleItems(), paidPaise: '6010', method: 'CASH'),
        isFalse);
    expect(f.writes, isEmpty);
    expect(m.queue, isEmpty);
    store.fail = false;
    f.rejection = 409;
    await m.enqueue('rejected', saleItems(), paidPaise: '6010', method: 'CASH');
    expect(m.queue.single.rejected, isTrue);
    expect(m.available(syntheticProductId), 12);
    expect(f.commits, 0);
    await m.discard('rejected');
    expect(m.queue, isEmpty);
    f.rejection = null;
    f.offline = true;
    await m.enqueue('uncertain', saleItems(),
        paidPaise: '6010', method: 'CASH');
    await m.discard('uncertain');
    expect(m.queue, hasLength(1));
  });
  test(
      'TC-059 six failures stop automatic retry; denied role/plan hides cache and requires explicit retry',
      () async {
    final f = SalesFixture(), m = salesModel(f, MemoryDrafts());
    addTearDown(() => closeSales(m));
    await m.load();
    f.offline = true;
    await m.enqueue('bounded', saleItems(), paidPaise: '6010', method: 'CASH');
    for (var i = 0; i < 5; i++) {
      m.queue.first.nextAt = null;
      await m.flush();
    }
    expect(m.queue.first.retryable, isTrue);
    final calls = f.writes.length;
    await m.flush();
    expect(f.writes, hasLength(calls));
    f.offline = false;
    f.denial = 403;
    await m.flush(retry: true);
    expect(m.products, isEmpty);
    expect(m.customers, isEmpty);
    expect(m.queue.first.retryable, isTrue);
    f.denial = null;
    await m.flush(retry: true);
    expect(f.commits, 1);
    expect(m.queue, isEmpty);
  });
  test('T-080 catalog/customer paging and late-dispose reads retain scope',
      () async {
    final f = SalesFixture(), m = salesModel(f, MemoryDrafts());
    for (var i = 1; i < 105; i++) {
      final id = '${i.toString().padLeft(8, '0')}-3333-4333-8333-333333333333';
      f.products.add(productJson(id: id));
      f.customers.add(customerJson(id: id));
    }
    await m.load();
    expect(m.products, hasLength(105));
    expect(m.customers, hasLength(105));
    f.gate = Completer<void>();
    final active = m.load();
    await Future<void>.delayed(Duration.zero);
    closeSales(m);
    f.gate!.complete();
    await active;
    expect(m.canCreate, isFalse);
  });
  testWidgets(
      'TC-058 whole-pack and rate edits show exact totals and block walk-in partial at 200%',
      (tester) async {
    final f = SalesFixture(), m = salesModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    await tester.pumpWidget(salesApp(m, scale: 2));
    await settleSales(tester, m);
    await reveal(tester, find.widgetWithText(SbButton, 'Add product').first);
    await tester.tap(find.widgetWithText(SbButton, 'Add product').first);
    await tester.pumpAndSettle();
    await reveal(
        tester, find.widgetWithText(TextFormField, 'Quantity (whole packs)'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity (whole packs)'), '2');
    await reveal(
        tester, find.widgetWithText(TextFormField, 'Rate per pack (₹)'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Rate per pack (₹)'), '65.00');
    await tester.pumpAndSettle();
    expect(find.textContaining('₹130.00'), findsWidgets);
    await reveal(tester, find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await reveal(tester, find.widgetWithText(SbButton, 'Complete Sale'));
    expect(
        tester
            .widget<SbButton>(find.widgetWithText(SbButton, 'Complete Sale'))
            .onPressed,
        isNull);
    expect(f.commits, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.dio.close(force: true);
  });
  testWidgets(
      'TC-055 completed draft disables duplicate send and shows a server receipt',
      (tester) async {
    final f = SalesFixture(), m = salesModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    await tester.pumpWidget(salesApp(m));
    await settleSales(tester, m);
    await reveal(tester, find.widgetWithText(SbButton, 'Add product').first);
    await tester.tap(find.widgetWithText(SbButton, 'Add product').first);
    await tester.pumpAndSettle();
    await reveal(tester, find.widgetWithText(SbButton, 'Complete Sale'));
    await tester.tap(find.widgetWithText(SbButton, 'Complete Sale'));
    await tester.pumpAndSettle();
    expect(f.commits, 0);
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(f.commits, 1);
    expect(find.widgetWithText(SbButton, 'Complete Sale'), findsNothing);
    expect(find.text('Sale confirmed: SALE1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.dio.close(force: true);
  });
}
