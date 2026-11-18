import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/khata/customer_khata_controller.dart';
import 'package:supplybiz_mobile/features/khata/customer_khata_page.dart';
import 'package:supplybiz_mobile/features/khata/upi_device.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/addresses_test.dart' show reveal;
import 'customer_khata_fixture.dart';

CustomerKhataController model(CustomerKhataFixture f, MemoryDrafts store,
        {String scope = 'home', TestUpi? device, String user = 'synthetic'}) =>
    CustomerKhataController(
        NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: f,
            delay: (_) async {}),
        store,
        '$user:$scope',
        scope,
        device: device);
void closeModel(CustomerKhataController m) {
  m.dispose();
  m.client.close();
}

Future<void> ready(CustomerKhataController m) async {
  await m.load();
  expect(m.failure, isNull);
}

Widget app(CustomerKhataController m, {double scale = 1}) => ProviderScope(
    overrides: [customerKhataProvider(m.scope).overrideWith((ref) => m)],
    child: MaterialApp(
        theme: sbLightTheme(const Locale('en')),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...SbLocalizations.delegates
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (c, child) => MediaQuery(
            data:
                MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: CustomerKhataPage(scope: m.scope)));
Future<void> settle(WidgetTester t, CustomerKhataController m) async {
  await t.runAsync(() async {
    for (var i = 0; i < 100 && m.busy; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'TC-250 full summary pagination, local filters and huge paise retain global totals',
      () async {
    final f = CustomerKhataFixture(), m = model(f, MemoryDrafts());
    addTearDown(() => closeModel(m));
    f.rows.addAll([
      for (var i = 0; i < 51; i++)
        {...f.rows.first, 'id': '$i', 'name': 'Extra $i'}
    ]);
    await ready(m);
    expect(m.accounts, hasLength(53));
    expect(m.summary!.totalReceivablePaise, '9007199254740993');
    m.filter('', 'CUSTOMERS');
    expect(m.filtered, hasLength(1));
    m.filter('Extra 50', 'VENDORS');
    expect(m.filtered, hasLength(1));
    expect(m.summary!.netBalancePaise, '9007199254730993');
  });
  test(
      'TC-251/252 month reader retains snapshots, source status and loads later entries',
      () async {
    final f = CustomerKhataFixture()..entryTotal = 51,
        m = model(f, MemoryDrafts(), scope: 'vendor:$khataVendor');
    addTearDown(() => closeModel(m));
    await ready(m);
    expect(m.entries!.items, hasLength(50));
    await m.moreEntries();
    expect(m.entries!.items, hasLength(51));
    await m.selectMonth('2026-10');
    expect(m.entries!.month, '2026-10');
    expect(m.entries!.items.first.productSummary, 'Milk: 2 packs');
    expect(m.entries!.items.first.paymentStatus, 'PENDING');
    expect(m.entries!.openingDuePaise, '-500');
  });
  test(
      'TC-253 generated owned personal CRUD preserves exact amount/date, versions, DELETE body and clear mobile',
      () async {
    final f = CustomerKhataFixture(),
        m = model(f, MemoryDrafts(), scope: 'personal:$khataContact');
    addTearDown(() => closeModel(m));
    await ready(m);
    for (final action in [
      'CONTACT_CREATE',
      'CONTACT_PATCH',
      'ENTRY_CREATE',
      'ENTRY_PATCH',
      'ENTRY_DELETE',
      'CONTACT_DELETE'
    ]) {
      final body = <String, dynamic>{
        if (action == 'CONTACT_CREATE') 'name': 'Synthetic contact',
        if (action == 'CONTACT_PATCH') ...{
          'version': 1,
          'name': 'Synthetic changed',
          'clearMobile': true
        },
        if (action.startsWith('ENTRY') && !action.endsWith('DELETE')) ...{
          'contactId': khataContact,
          'direction': 'GOT',
          'amountPaise': '9007199254740993',
          'date': '2026-11-18',
          'note': ''
        },
        if (action == 'ENTRY_PATCH' || action.endsWith('DELETE')) 'version': 1
      };
      await m.submit(action, body,
          id: action.startsWith('ENTRY') ? khataEntry : khataContact);
      expect(m.failure, isNull);
      expect(jsonDecode(f.writes.last.data as String), body);
      expect(f.writes.last.headers['Idempotency-Key'], isNotEmpty);
    }
    expect(m.deleted, isTrue);
    expect(m.canWrite, isFalse);
  });
  test(
      'TC-254 return/cancel never claims automatically; explicit paid creates only PENDING without moving due',
      () async {
    final f = CustomerKhataFixture(),
        d = TestUpi(),
        m = model(f, MemoryDrafts(), scope: 'vendor:$khataVendor', device: d);
    addTearDown(() => closeModel(m));
    await ready(m);
    await m.settlementOptions();
    await m.pay(khataVendor, BigInt.from(1234), 'UPI');
    expect(d.opened.single.queryParameters, {
      'pa': 'synthetic@bank',
      'pn': 'Synthetic vendor',
      'am': '12.34',
      'cu': 'INR',
      'tn': 'Supply Biz Khata'
    });
    expect(f.writes, isEmpty);
    expect(m.launch, isNotNull);
    await m.confirmPaid();
    expect(m.failure, isNull);
    expect(m.launch, isNull);
    expect(m.claims.single.status.value, 'PENDING');
    expect(m.entries!.duePaise, '10000');
    expect(jsonDecode(f.writes.single.data as String), {
      'vendorCustomerId': khataVendor,
      'amountPaise': '1234',
      'method': 'UPI'
    });
  });
  test(
      'TC-254 no handler keeps exact URI/VPA for QR and cancellation writes nothing',
      () async {
    final f = CustomerKhataFixture(),
        d = TestUpi()..handled = false,
        m = model(f, MemoryDrafts(), scope: 'vendor:$khataVendor', device: d);
    addTearDown(() => closeModel(m));
    await ready(m);
    await m.settlementOptions();
    await m.pay(khataVendor, BigInt.one, 'UPI');
    expect(m.launch!['fallback'], isTrue);
    expect(m.launch!['uri'], d.opened.single.toString());
    await m.dismissPayment();
    expect(m.launch, isNull);
    expect(f.writes, isEmpty);
  });
  test(
      'T-083 launch draft is saved before external app; recreation never relaunches or claims, other owner sees none',
      () async {
    final f = CustomerKhataFixture(), store = MemoryDrafts(), d = TestUpi();
    final first = model(f, store, scope: 'vendor:$khataVendor', device: d);
    await ready(first);
    await first.settlementOptions();
    d.duringOpen = () async {
      expect(store.rows.values.single['launch'], contains('synthetic@bank'));
      closeModel(
          first); // Simulate activity/process loss while external UI is open.
    };
    await first.pay(khataVendor, BigInt.from(300), 'UPI');
    final second = model(f, store, scope: 'vendor:$khataVendor', device: d);
    final other = model(f, store,
        scope: 'vendor:$khataVendor', device: d, user: 'another');
    addTearDown(() => closeModel(second));
    addTearDown(() => closeModel(other));
    await ready(second);
    await ready(other);
    expect(second.canReview, isTrue);
    expect(other.launch, isNull);
    expect(d.opened, hasLength(1));
    expect(f.writes, isEmpty);
    await second.confirmPaid();
    expect(f.commits, 1);
  });
  test(
      'TC-255 unset VPA cash-only and due/account cap rejects zero/negative/overdue and unknown account',
      () async {
    final f = CustomerKhataFixture()
          ..vpa = null
          ..maxClaim = '5000',
        d = TestUpi(),
        m = model(f, MemoryDrafts(), scope: 'vendor:$khataVendor', device: d);
    addTearDown(() => closeModel(m));
    await ready(m);
    await m.settlementOptions();
    for (final n in [0, -1, 5001, 10001]) {
      await m.pay(khataVendor, BigInt.from(n), 'CASH');
    }
    await m.pay(khataContact, BigInt.one, 'CASH');
    await m.pay(khataVendor, BigInt.one, 'UPI');
    expect(f.writes, isEmpty);
    expect(d.opened, isEmpty);
    await m.pay(khataVendor, BigInt.from(5000), 'CASH');
    expect(m.claims.single.method.value, 'CASH');
  });
  test(
      'TC-255 changed payee/due requires review and no payment launches from offline cache',
      () async {
    final f = CustomerKhataFixture(),
        d = TestUpi(),
        m = model(f, MemoryDrafts(), scope: 'vendor:$khataVendor', device: d);
    addTearDown(() => closeModel(m));
    await ready(m);
    await m.settlementOptions();
    f.vpa = 'changed@bank';
    await m.pay(khataVendor, BigInt.one, 'UPI');
    expect(m.failure!.code, 'PAYMENT_DETAILS_CHANGED');
    expect(d.opened, isEmpty);
    await ready(m);
    await m.settlementOptions();
    f.offline = true;
    await m.pay(khataVendor, BigInt.one, 'UPI');
    expect(d.opened, isEmpty);
    expect(f.writes, isEmpty);
  });
  test(
      'T-083 lost claim response survives recreation and retries one immutable key/body; accepted ack disk failure also replays',
      () async {
    final f = CustomerKhataFixture(),
        store = MemoryDrafts(),
        first = model(f, store, scope: 'vendor:$khataVendor');
    await ready(first);
    await first.settlementOptions();
    f.loseResponse = true;
    await first.pay(khataVendor, BigInt.from(100), 'CASH');
    final p = jsonEncode(first.pending), key = first.pending!['key'];
    closeModel(first);
    final second = model(f, store, scope: 'vendor:$khataVendor');
    addTearDown(() => closeModel(second));
    await ready(second);
    expect(jsonEncode(second.pending), p);
    expect(f.writes, hasLength(1));
    await second.retry();
    expect(second.pending, isNull);
    expect(f.commits, 1);
    expect(f.writes.last.headers['Idempotency-Key'], key);
    await second.settlementOptions();
    f.afterCommit = () => store.fail = true;
    await second.pay(khataVendor, BigInt.from(200), 'CASH');
    expect(second.pending, isNotNull);
    store.fail = false;
    f.afterCommit = null;
    await second.retry();
    expect(f.commits, 2);
    expect(second.pending, isNull);
  });
  test(
      'T-083 failed encrypted save prevents native launch; authorization denial hides cached private data',
      () async {
    final f = CustomerKhataFixture(),
        store = MemoryDrafts(),
        d = TestUpi(),
        m = model(f, store, scope: 'vendor:$khataVendor', device: d);
    addTearDown(() => closeModel(m));
    await ready(m);
    await m.settlementOptions();
    store.fail = true;
    await m.pay(khataVendor, BigInt.one, 'UPI');
    expect(d.opened, isEmpty);
    expect(f.writes, isEmpty);
    store.fail = false;
    f.denial = 403;
    await m.load();
    expect(m.summary, isNull);
    expect(m.entries, isNull);
    expect(m.canReview, isFalse);
  });
  test(
      'T-083 definitive claim conflict clears attempt and requires refreshed review',
      () async {
    final f = CustomerKhataFixture(),
        m = model(f, MemoryDrafts(), scope: 'vendor:$khataVendor');
    addTearDown(() => closeModel(m));
    await ready(m);
    await m.settlementOptions();
    f.rejection = 409;
    await m.pay(khataVendor, BigInt.one, 'CASH');
    expect(m.pending, isNull);
    expect(m.canWrite, isFalse);
    f.rejection = null;
    await ready(m);
    expect(m.canWrite, isTrue);
  });
  test(
      'T-083 UPI bridge ignores non-boolean provider status and validates exact URI/paise',
      () async {
    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    binding.setMockMethodCallHandler(UpiDevice.channel, (call) async => true);
    addTearDown(
        () => binding.setMockMethodCallHandler(UpiDevice.channel, null));
    final uri = khataUpiUri('synthetic@bank', 'Synthetic & vendor',
        BigInt.parse('9007199254740993'));
    expect(uri.queryParameters['am'], '90071992547409.93');
    expect(uri.queryParameters['pn'], 'Synthetic & vendor');
    expect(await UpiDevice().open(uri), isTrue);
    binding.setMockMethodCallHandler(UpiDevice.channel,
        (call) async => {'Status': 'SUCCESS', 'txnId': 'synthetic'});
    expect(await UpiDevice().open(uri), isFalse);
    binding.setMockMethodCallHandler(UpiDevice.channel,
        (call) async => throw PlatformException(code: 'NO_HANDLER'));
    expect(await UpiDevice().open(uri), isFalse);
    for (final v in ['bad', 'a@x', '../../x@bank']) {
      expect(
          () => khataUpiUri(v, 'Synthetic', BigInt.one), throwsFormatException);
    }
    expect(() => khataUpiUri('synthetic@bank', 'Synthetic', BigInt.zero),
        throwsFormatException);
  });
  testWidgets(
      'TC-253 personal form at 200% validates, then sends GAVE 200 with server date',
      (t) async {
    final f = CustomerKhataFixture();
    late CustomerKhataController m;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts(), scope: 'personal:$khataContact');
      await ready(m);
    });
    await t.pumpWidget(app(m, scale: 2));
    await settle(t, m);
    await reveal(t, find.text('Add personal entry'));
    await t.tap(find.text('Add personal entry'));
    await t.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await t.ensureVisible(
        find.descendant(of: dialog, matching: find.text('Confirm')));
    await t.tap(find.descendant(of: dialog, matching: find.text('Confirm')));
    await t.pumpAndSettle();
    expect(find.textContaining('Enter a valid name'), findsOneWidget);
    await t.enterText(
        find.descendant(of: dialog, matching: find.byType(TextField)).at(0),
        '200');
    await t.ensureVisible(
        find.descendant(of: dialog, matching: find.text('Confirm')));
    await t.tap(find.descendant(of: dialog, matching: find.text('Confirm')));
    await settle(t, m);
    expect(jsonDecode(f.writes.single.data as String), {
      'contactId': khataContact,
      'direction': 'GAVE',
      'amountPaise': '20000',
      'date': '2026-11-18',
      'note': ''
    });
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'TC-254 fallback shows QR, VPA and explicit confirmation at 200%; never claims on render',
      (t) async {
    final f = CustomerKhataFixture(), d = TestUpi()..handled = false;
    late CustomerKhataController m;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts(), scope: 'vendor:$khataVendor', device: d);
      await ready(m);
      await m.settlementOptions();
      await m.pay(khataVendor, BigInt.from(300), 'UPI');
    });
    await t.pumpWidget(app(m, scale: 2));
    await settle(t, m);
    await reveal(t, find.byType(KhataPaymentQr));
    expect(find.byType(KhataPaymentQr), findsOneWidget);
    await reveal(t, find.text('Copy UPI ID'));
    expect(find.text('Copy UPI ID'), findsOneWidget);
    expect(f.writes, isEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'TC-255 settlement form exposes cash only when payment VPA is unset',
      (t) async {
    final f = CustomerKhataFixture()..vpa = null;
    late CustomerKhataController m;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts(), scope: 'vendor:$khataVendor');
      await ready(m);
    });
    await t.pumpWidget(app(m));
    await settle(t, m);
    await reveal(t, find.text('Settle dues'));
    await t.tap(find.text('Settle dues'));
    await settle(t, m);
    expect(find.text('Open UPI app'), findsNothing);
    expect(find.text('I paid cash - submit claim'), findsOneWidget);
    expect(find.byType(KhataPaymentQr), findsNothing);
    expect(f.writes, isEmpty);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
}
