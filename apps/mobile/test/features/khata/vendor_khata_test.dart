import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/khata/vendor_khata_controller.dart';
import 'package:supplybiz_mobile/features/khata/vendor_khata_page.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/addresses_test.dart' show reveal;
import 'vendor_khata_fixture.dart';

VendorKhataController vendorKhataModel(
        VendorKhataFixture f, OnboardingDrafts store,
        {String owner = 'synthetic:vendor-khata'}) =>
    VendorKhataController(
        NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: f,
            delay: (_) async {}),
        store,
        owner);
void closeKhata(VendorKhataController m) {
  m.dispose();
  m.client.close();
}

Widget vendorKhataApp(VendorKhataController m,
        {Widget? page, double scale = 1}) =>
    ProviderScope(
        overrides: [vendorKhataProvider.overrideWith((ref) => m)],
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
            home: page ?? const VendorKhataPage()));
Future<void> settleKhata(WidgetTester tester, VendorKhataController m) async {
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
      'TC-110 all customer pages/tabs preserve huge signed amounts and global totals',
      () async {
    final f = VendorKhataFixture(), m = vendorKhataModel(f, MemoryDrafts());
    addTearDown(() => closeKhata(m));
    f.rows.addAll([
      vendorAccount(id: vendorClaimId, due: '0'),
      vendorAccount(id: '33333333-3333-4333-8333-333333333333', due: '-5000'),
      for (var i = 1; i <= 51; i++)
        vendorAccount(
            id: '${i.toString().padLeft(8, '0')}-5555-4555-8555-555555555555')
    ]);
    await m.load();
    expect(m.failure, isNull);
    expect(m.accounts, hasLength(54));
    expect(m.summary!.totalReceivablePaise, '9007199254740993');
    m.filter('', 'PAID');
    expect(m.filtered, hasLength(1));
    m.filter('', 'RECEIVABLE');
    expect(m.filtered, hasLength(52));
    m.filter('nobody', 'ALL');
    expect(m.filtered, isEmpty);
    expect(m.summary!.totalReceivablePaise, '9007199254740993');
  });
  test(
      'TC-111/112/114/116 generated mutations preserve exact amount, calendar date, type, reason and version',
      () async {
    final f = VendorKhataFixture(), m = vendorKhataModel(f, MemoryDrafts());
    addTearDown(() => closeKhata(m));
    await m.load();
    final payment = {
      'vendorCustomerId': vendorAccountId,
      'amountPaise': '9007199254740993',
      'method': 'BANK',
      'receivedOn': '2026-11-18',
      'note': 'Synthetic payment'
    };
    await m.submit('PAYMENT', payment);
    expect(m.failure, isNull);
    expect(jsonDecode(f.writes.last.data as String), payment);
    expect(m.completed, isTrue);
    for (final action in ['OPENING', 'REVERSE', 'REJECT']) {
      final body = <String, dynamic>{
        if (action == 'OPENING') ...{
          'type': 'CREDIT',
          'amountPaise': '5000',
          'note': 'Synthetic opening'
        },
        if (action == 'REVERSE') 'reason': 'Synthetic correction',
        if (action == 'REJECT') ...{
          'version': 1,
          'reason': 'Synthetic rejection'
        }
      };
      await m.submit(action, body,
          id: action == 'OPENING' ? vendorAccountId : vendorClaimId);
      expect(m.failure, isNull);
      expect(jsonDecode(f.writes.last.data as String), body);
      expect(f.writes.last.headers['Idempotency-Key'], isNotEmpty);
    }
  });
  test(
      'T-081 uncertain payment survives recreation, never auto-resends and replays one key/body',
      () async {
    final f = VendorKhataFixture(),
        store = MemoryDrafts(),
        first = vendorKhataModel(f, store);
    await first.load();
    f.loseResponse = true;
    await first.submit('PAYMENT', {
      'vendorCustomerId': vendorAccountId,
      'amountPaise': '100',
      'method': 'CASH',
      'receivedOn': '2026-11-18'
    });
    final saved = jsonEncode(first.pending), key = first.pending!['key'];
    expect(first.pending, isNotNull);
    closeKhata(first);
    final next = vendorKhataModel(f, store);
    addTearDown(() => closeKhata(next));
    await next.load();
    expect(jsonEncode(next.pending), saved);
    expect(f.writes, hasLength(1));
    expect(next.canWrite, isFalse);
    await next.retry();
    expect(next.pending, isNull);
    expect(f.commits, 1);
    expect(f.writes.last.headers['Idempotency-Key'], key);
    f.afterCommit = () => store.fail = true;
    await next.submit('OPENING',
        {'type': 'DEBIT', 'amountPaise': '100', 'note': 'Synthetic note'},
        id: vendorAccountId);
    expect(next.pending, isNotNull);
    store.fail = false;
    f.afterCommit = null;
    await next.retry();
    expect(f.commits, 2);
  });
  test(
      'T-081 storage failure sends nothing; conflict clears attempt and requires refreshed review',
      () async {
    final f = VendorKhataFixture(),
        store = MemoryDrafts(),
        m = vendorKhataModel(f, store);
    addTearDown(() => closeKhata(m));
    await m.load();
    store.fail = true;
    await m.submit(
        'OPENING', {'type': 'DEBIT', 'amountPaise': '100', 'note': 'Synthetic'},
        id: vendorAccountId);
    expect(f.writes, isEmpty);
    expect(m.pending, isNotNull);
    store.fail = false;
    await m.retry();
    expect(f.commits, 1);
    f.rejection = 409;
    await m.submit('REVERSE', {'reason': 'Synthetic correction'},
        id: vendorClaimId);
    expect(m.pending, isNull);
    expect(m.canWrite, isFalse);
    f.rejection = null;
    await m.load();
    expect(m.canWrite, isTrue);
  });
  test(
      'T-081 stale/denied cache cannot authorize writes or show another selected customer ledger',
      () async {
    final f = VendorKhataFixture(),
        store = MemoryDrafts(),
        first = vendorKhataModel(f, store);
    await first.load(id: vendorAccountId);
    expect(first.entries, isNotNull);
    closeKhata(first);
    f.offline = true;
    final next = vendorKhataModel(f, store);
    addTearDown(() => closeKhata(next));
    await next.load(id: vendorClaimId);
    expect(next.entries, isNull);
    expect(next.canPay, isFalse);
    await next.submit('CONFIRM', {'version': 1}, id: vendorClaimId);
    expect(f.writes, isEmpty);
    final other = vendorKhataModel(f, store, owner: 'other:vendor-khata');
    addTearDown(() => closeKhata(other));
    await other.load();
    expect(other.accounts, isEmpty);
    expect(other.pending, isNull);
    f.offline = false;
    await next.load();
    f.loseResponse = true;
    await next.submit('CONFIRM', {'version': 1}, id: vendorClaimId);
    final key = next.pending!['key'];
    f.denial = 403;
    await next.load();
    expect(next.accounts, isEmpty);
    expect(next.summary, isNull);
    expect(next.pending!['key'], key);
    f.denial = null;
    await next.retry();
    expect(f.commits, 1);
  });
  test(
      'T-081 expiry flags fence new adjustments while payment/claim settlement and original retries remain',
      () async {
    final f = VendorKhataFixture()..canAdjust = false,
        m = vendorKhataModel(f, MemoryDrafts());
    addTearDown(() => closeKhata(m));
    await m.load();
    expect(m.canAdjust, isFalse);
    expect(m.canPay, isTrue);
    await m.submit(
        'OPENING', {'type': 'DEBIT', 'amountPaise': '100', 'note': 'Synthetic'},
        id: vendorAccountId);
    expect(f.writes, isEmpty);
    await m.submit('CONFIRM', {'version': 1}, id: vendorClaimId);
    expect(f.commits, 1);
  });
  test(
      'T-081 detail and collection pages keep selected month and typed reversal data',
      () async {
    final f = VendorKhataFixture()
          ..entryTotal = 51
          ..collectionTotal = 51,
        m = vendorKhataModel(f, MemoryDrafts());
    addTearDown(() => closeKhata(m));
    await m.load(id: vendorAccountId);
    expect(m.entries!.items, hasLength(50));
    await m.moreEntries();
    expect(m.entries!.items, hasLength(51));
    await m.moreCollections();
    expect(m.collections, hasLength(51));
    expect(m.collections[1].amountPaise, '-1000');
    await m.selectMonth('2026-10');
    expect(m.entries!.month, '2026-10');
    expect(f.calls.last.queryParameters['month'], '2026-10');
  });
  testWidgets(
      'TC-112/116 opening needs reason; dialog owns fields through close and reversals retain original at 200%',
      (tester) async {
    final f = VendorKhataFixture(), m = vendorKhataModel(f, MemoryDrafts());
    await tester.runAsync(() => m.load(id: vendorAccountId));
    await tester.pumpWidget(vendorKhataApp(m,
        page: const VendorKhataPage(id: vendorAccountId), scale: 2));
    await settleKhata(tester, m);
    await reveal(tester, find.widgetWithText(SbButton, 'Opening balance'));
    await tester.tap(find.widgetWithText(SbButton, 'Opening balance'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(f.writes, isEmpty);
    expect(find.textContaining('Check the required'), findsWidgets);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount (₹)'), '50.00');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Reason'), 'Synthetic opening');
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
      for (var i = 0; i < 100 && m.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(f.commits, 1);
    expect(jsonDecode(f.writes.single.data as String),
        {'type': 'DEBIT', 'amountPaise': '5000', 'note': 'Synthetic opening'});
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'TC-114 claims require explicit confirmation and hide undefined settlement actions',
      (tester) async {
    final f = VendorKhataFixture(), m = vendorKhataModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    await tester.pumpWidget(
        vendorKhataApp(m, page: const VendorKhataPage(paymentsOnly: true)));
    await settleKhata(tester, m);
    expect(find.text('Settle to Bank'), findsNothing);
    await reveal(
        tester, find.widgetWithText(SbButton, 'Confirm payment claim'));
    await tester.tap(find.widgetWithText(SbButton, 'Confirm payment claim'));
    await tester.pumpAndSettle();
    expect(f.writes, isEmpty);
    expect(find.textContaining('not verified payment'), findsWidgets);
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
      for (var i = 0; i < 100 && m.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(f.commits, 1);
    expect(jsonDecode(f.writes.single.data as String), {'version': 1});
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.client.close();
  });
}
