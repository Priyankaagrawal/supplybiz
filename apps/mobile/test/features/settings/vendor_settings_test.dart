// T-106 / TC-130/131: exact amounts, persisted intent, denial, secure-revision reuse and UI smoke.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/settings/vendor_settings_controller.dart';
import 'package:supplybiz_mobile/features/settings/vendor_settings_page.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart'
    show MemoryDrafts, TestSession, OnboardingFixture, categoryId;
import '../addresses/addresses_test.dart' show reveal;

class Fixture extends OnboardingFixture {
  Fixture() {
    step = 4;
    status = 'VERIFIED';
  }
  int version = 1;
  bool loseWrite = false, conflict = false, denied = false;
  Completer<void>? gate, started;
  @override
  Map<String, dynamic> get profile => {
        ...super.profile,
        'kycStatus': status,
        'settings': {
          ...super.profile['settings'] as Map,
          'sameDayCutoff': null,
          'version': version
        }
      };
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    ResponseBody json(Object value, [int code = 200]) =>
        ResponseBody.fromString(jsonEncode(value), code, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (denied) return json({'code': 'VENDOR_SUSPENDED'}, 403);
    if (o.method == 'PUT') {
      calls.add(o);
      if (conflict) return json({'code': 'VERSION_CONFLICT'}, 409);
      if (loseWrite) {
        loseWrite = false;
        throw DioException(
            requestOptions: o, type: DioExceptionType.receiveTimeout);
      }
      if (o.path.endsWith('/kyc')) {
        status = 'PENDING';
        return json({
          ...kyc,
          'status': status,
          'id': '22222222-2222-4222-8222-222222222222'
        });
      }
      version++;
      return json(profile);
    }
    if (o.path.endsWith('/profile') && gate != null) {
      started?.complete();
      await gate!.future;
    }
    return super.fetch(o, stream, cancel);
  }
}

NetworkClient client(Fixture f) => NetworkClient(
    baseUrl: 'https://api.example.test',
    adapter: f,
    session: TestSession(),
    delay: (_) async {});
Map<String, dynamic> delivery() => {
      'version': 1,
      'deliveryChargePaise': 505,
      'minOrderPaise': 0,
      'timeSlots': ['07:00-08:00'],
      'acceptingToday': true,
      'sameDayCutoff': '21:00'
    };
Widget app(VendorSettingsController m, String section) => ProviderScope(
    overrides: [vendorSettingsProvider.overrideWith((ref) => m)],
    child: MaterialApp(
        theme: sbLightTheme(const Locale('en')),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...SbLocalizations.delegates
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: VendorSettingsPage(section: section)));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'exact rupees to integer paise rejects fractional paise, overflow and exponent notation',
      () {
    expect(settingsPaise('5.05'), 505);
    expect(settingsPaise('21474836.47'), 2147483647);
    for (final v in ['21474836.48', '0.001', '1e3', '-1', 'NaN']) {
      expect(settingsPaise(v), isNull);
    }
  });
  test(
      'lost settings response survives recreation and retry uses identical key/body despite changed form',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        a = client(f),
        m = VendorSettingsController(a, store, 'one');
    await m.load();
    f.loseWrite = true;
    await m.save('delivery', delivery());
    expect(m.pending, isTrue);
    final first = f.calls.where((c) => c.method == 'PUT').single;
    m.dispose();
    a.close();
    final b = client(f), n = VendorSettingsController(b, store, 'one');
    addTearDown(() {
      n.dispose();
      b.close();
    });
    await n.load();
    await n
        .save('business', {'businessName': 'Must not replace pending request'});
    final last = f.calls.where((c) => c.method == 'PUT').last;
    expect(last.data, first.data);
    expect(last.headers['Idempotency-Key'], first.headers['Idempotency-Key']);
    expect(n.pending, isFalse);
  });
  test(
      'durable-write failure sends nothing; definitive conflict needs explicit review before editing',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        a = client(f),
        m = VendorSettingsController(a, store, 'one');
    addTearDown(() {
      m.dispose();
      a.close();
    });
    await m.load();
    store.fail = true;
    await m.save('delivery', delivery());
    expect(f.calls.where((c) => c.method == 'PUT'), isEmpty);
    store.fail = false;
    f.conflict = true;
    await m.retry();
    expect(m.terminal, isTrue);
    expect(m.pending, isTrue);
    f.conflict = false;
    await m.reviewConflict();
    expect(m.pending, isFalse);
    expect(m.failure, isNull);
  });
  test(
      'offline saved profile is stale and cannot write; another owner sees no cache; denial clears data',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        a = client(f),
        m = VendorSettingsController(a, store, 'one');
    await m.load();
    m.dispose();
    a.close();
    final b = client(f), n = VendorSettingsController(b, store, 'one');
    addTearDown(() {
      n.dispose();
      b.close();
    });
    f.offline = true;
    await n.load();
    expect(n.stale, isTrue);
    expect(n.profile, isNotNull);
    await n.save('delivery', delivery());
    expect(f.calls.where((c) => c.method == 'PUT'), isEmpty);
    final c = client(f), other = VendorSettingsController(c, store, 'other');
    addTearDown(() {
      other.dispose();
      c.close();
    });
    await other.load();
    expect(other.profile, isNull);
    f.offline = false;
    f.denied = true;
    await n.load();
    expect(n.profile, isNull);
    expect(store.rows['one'], isEmpty);
  });
  test('late reads cannot publish or persist after disposal', () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        a = client(f),
        m = VendorSettingsController(a, store, 'one');
    f.gate = Completer<void>();
    f.started = Completer<void>();
    final load = m.load();
    await f.started!.future;
    m.dispose();
    f.gate!.complete();
    await load;
    a.close();
    expect(m.profile, isNull);
    expect(store.rows, isEmpty);
  });
  test(
      're-verification freezes encrypted draft and bank intent across recreation; accepted secrets are cleared',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        a = client(f),
        m = OnboardingController(a, store, 'kyc', reverification: true);
    await m.load();
    for (final e in {
      'pan': 'ABCDE1234F',
      'accountNumber': '000000000001',
      'accountNumberConfirmation': '000000000001'
    }.entries) {
      m.edit(e.key, e.value);
    }
    await m.flush();
    f.loseWrite = true;
    await m.submit();
    expect(m.revisionPending, isTrue);
    final first = f.calls.where((c) => c.method == 'PUT').single;
    m.edit('accountNumber', '000000000002');
    expect(m.values['accountNumber'], '000000000001');
    m.dispose();
    a.close();
    final b = client(f),
        n = OnboardingController(b, store, 'kyc', reverification: true);
    addTearDown(() {
      n.dispose();
      b.close();
    });
    await n.load();
    await n.submit();
    await n.flush();
    final last = f.calls.where((c) => c.method == 'PUT').last;
    expect(last.data, first.data);
    expect(last.headers['Idempotency-Key'], first.headers['Idempotency-Key']);
    expect(n.submission!.status, 'PENDING');
    expect(n.revisionPending, isFalse);
    expect(store.rows['kyc']!['accountNumber'], isNull);
    expect(
        jsonDecode(first.data as String)['expectedSubmissionId'], categoryId);
  });
  testWidgets(
      'business warning and delivery forms render with 200% text; same-day cutoff validates before send',
      (t) async {
    final f = Fixture(), store = MemoryDrafts(), a = client(f);
    late VendorSettingsController m;
    await t.runAsync(() async {
      m = VendorSettingsController(a, store, 'one');
      await m.load();
    });
    await t.pumpWidget(app(m, 'business'));
    await t.pumpAndSettle();
    expect(
        find.textContaining('hidden from customer discovery'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    a.close();
    final b = client(f);
    late VendorSettingsController n;
    await t.runAsync(() async {
      n = VendorSettingsController(b, store, 'two');
      await n.load();
    });
    await t.pumpWidget(app(n, 'delivery'));
    await t.pumpAndSettle();
    await reveal(t, find.text('Accept same-day orders'));
    expect(t.widget<Switch>(find.byType(Switch)).value, isTrue);

    await reveal(t, find.text('Save settings'));
    await t.tap(find.text('Save settings'));
    await t.pumpAndSettle();
    expect(f.calls.where((c) => c.method == 'PUT'), isEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    b.close();
  });
}
