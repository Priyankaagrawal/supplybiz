// T-126 / TC-291/292/293. Focused owned transport, recovery, cache safety and UI.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/profile/profile_controller.dart';
import 'package:supplybiz_mobile/features/profile/profile_pages.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/addresses_test.dart' show reveal;

const id = '11111111-1111-4111-8111-111111111111',
    photoId = '22222222-2222-4222-8222-222222222222';

class Fixture implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  final accepted = <String, Map<String, dynamic>>{};
  bool offline = false, loseSave = false, expiredLegal = false;
  int? status;
  Completer<void>? gate, started;
  Map<String, dynamic> profile = {
    'id': id,
    'mobile': '+919000000000',
    'name': 'Synthetic name',
    'email': null,
    'photoMediaId': null,
    'updatedAt': '2026-11-19T01:00:00.000Z'
  };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    ResponseBody json(Object v, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(v), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    if (status != null) {
      return json(
          {'code': status == 409 ? 'VERSION_CONFLICT' : 'ACCOUNT_BLOCKED'},
          status!);
    }
    if (o.path.contains('/content/legal/')) {
      return expiredLegal
          ? json({'code': 'LEGAL_NOT_PUBLISHED'}, 404)
          : json({
              'type': 'TERMS',
              'version': 'synthetic-v1',
              'title': 'Synthetic terms',
              'text': 'Plain text <script>not HTML</script>',
              'sha256': 'a' * 64,
              'publishedAt': '2026-11-19T01:00:00Z'
            });
    }
    if (o.path.endsWith('/media') && o.method == 'POST') {
      await stream?.drain<void>();
      return json({'mediaId': photoId, 'status': 'READY'}, 201);
    }
    if (o.path.endsWith('/content')) {
      return ResponseBody.fromBytes([137, 80, 78, 71], 200,
          headers: {
            Headers.contentTypeHeader: ['image/png']
          });
    }
    if (o.method == 'PUT') {
      final key = o.headers['Idempotency-Key'] as String,
          body = jsonDecode(o.data as String) as Map<String, dynamic>;
      profile = accepted[key] ??
          {
            'id': id,
            'mobile': '+919000000000',
            'name': body['name'],
            'email': body['email'],
            'photoMediaId': body['photoMediaId'],
            'updatedAt': '2026-11-19T01:00:01.000Z'
          };
      accepted[key] = Map.of(profile);
      if (loseSave) {
        loseSave = false;
        throw DioException(
            requestOptions: o, type: DioExceptionType.receiveTimeout);
      }
    } else if (gate != null) {
      started?.complete();
      await gate!.future;
    }
    return json(profile);
  }
}

NetworkClient client(Fixture f) => NetworkClient(
    baseUrl: 'https://api.example.test',
    session: TestSession(),
    adapter: f,
    delay: (_) async {});
Widget app(ProfileController m, {String? section}) => ProviderScope(
    overrides: [profileProvider.overrideWith((ref) => m)],
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
        home: AccountProfilePage(section: section, customer: true)));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'save freezes exact own input, nullable fields and millisecond server version; no phone/status/role input',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        c = client(f),
        m = ProfileController(c, store, 'one');
    addTearDown(() {
      m.dispose();
      c.close();
    });
    await m.load();
    await m.save(' Updated name ', '');
    expect(jsonDecode(f.calls.last.data as String), {
      'expectedUpdatedAt': '2026-11-19T01:00:00.000Z',
      'name': 'Updated name',
      'email': null,
      'photoMediaId': null
    });
    expect(m.profile!.mobile, '+919000000000');
    expect(m.pending, isFalse);
  });
  test(
      'lost save survives recreation and explicit retry keeps original body/key despite edited arguments',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        c = client(f),
        m = ProfileController(c, store, 'one');
    await m.load();
    f.loseSave = true;
    await m.save('Saved name', 'synthetic@example.invalid');
    final first = f.calls.where((o) => o.method == 'PUT').single;
    expect(m.pending, isTrue);
    m.dispose();
    c.close();
    final d = client(f), n = ProfileController(d, store, 'one');
    addTearDown(() {
      n.dispose();
      d.close();
    });
    await n.load();
    await n.save('Different', 'changed@example.invalid');
    final last = f.calls.where((o) => o.method == 'PUT').last;
    expect(last.data, first.data);
    expect(last.headers['Idempotency-Key'], first.headers['Idempotency-Key']);
    expect(n.profile!.name, 'Saved name');
    expect(n.pending, isFalse);
  });
  test(
      'disk failure prevents a request; terminal conflict requires explicit review',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        c = client(f),
        m = ProfileController(c, store, 'one');
    addTearDown(() {
      m.dispose();
      c.close();
    });
    await m.load();
    store.fail = true;
    await m.save('Saved name', '');
    expect(f.calls.where((o) => o.method == 'PUT'), isEmpty);
    store.fail = false;
    f.status = 409;
    await m.retry();
    expect(m.terminal, isTrue);
    f.status = null;
    await m.review();
    expect(m.pending, isFalse);
    expect(m.failure, isNull);
  });
  test(
      'profile-cache clearing preserves frozen changes and other feature queues; refresh enables same retry',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        c = client(f),
        m = ProfileController(c, store, 'one');
    addTearDown(() {
      m.dispose();
      c.close();
    });
    store.rows['delivery'] = {'queue': 'synthetic-durable-delivery'};
    await m.load();
    f.loseSave = true;
    await m.save('Pending name', '');
    final key = m.pendingKey;
    await m.clearCache();
    expect(m.profile, isNull);
    expect(m.pendingKey, key);
    expect(store.rows['one']!.containsKey('profile'), isFalse);
    expect(store.rows['delivery'], {'queue': 'synthetic-durable-delivery'});
    await m.load();
    await m.retry();
    expect(m.pending, isFalse);
  });
  test(
      'offline cache cannot write; other identities see no profile; authorization denial clears private state',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        c = client(f),
        m = ProfileController(c, store, 'one');
    await m.load();
    m.dispose();
    c.close();
    f.offline = true;
    final d = client(f), n = ProfileController(d, store, 'one');
    addTearDown(() {
      n.dispose();
      d.close();
    });
    await n.load();
    expect(n.profile, isNotNull);
    expect(n.stale, isTrue);
    await n.save('New name', '');
    expect(f.calls.where((o) => o.method == 'PUT'), isEmpty);
    final e = client(f), other = ProfileController(e, store, 'other');
    addTearDown(() {
      other.dispose();
      e.close();
    });
    await other.load();
    expect(other.profile, isNull);
    f.offline = false;
    f.status = 403;
    await n.load();
    expect(n.profile, isNull);
    expect(store.rows['one'], isEmpty);
  });
  test(
      'photo is staged as owned PROFILE media before explicit save; removal sends null',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        c = client(f),
        m = ProfileController(c, store, 'one');
    addTearDown(() {
      m.dispose();
      c.close();
    });
    await m.load();
    await m.upload(Uint8List.fromList([137, 80, 78, 71]));
    final upload = f.calls.firstWhere((o) => o.method == 'POST');
    expect(upload.data, isA<FormData>());
    expect(
        (upload.data as FormData)
            .fields
            .any((entry) => entry.key == 'purpose' && entry.value == 'PROFILE'),
        isTrue);
    expect(upload.headers['Idempotency-Key'], isNotEmpty);
    expect(m.selectedPhoto, photoId);
    expect(f.calls.where((o) => o.method == 'PUT'), isEmpty);
    await m.save('Name', '');
    expect(m.profile!.photoMediaId, photoId);
    await m.removePhoto();
    await m.save('Name', '');
    expect(jsonDecode(f.calls.last.data as String)['photoMediaId'], isNull);
  });
  test('disposed controller cannot publish late profile or write cache',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        c = client(f),
        m = ProfileController(c, store, 'one');
    f.gate = Completer<void>();
    f.started = Completer<void>();
    final flight = m.load();
    await f.started!.future;
    m.dispose();
    f.gate!.complete();
    await flight;
    c.close();
    expect(m.profile, isNull);
    expect(store.rows, isEmpty);
  });
  test(
      'CMS legal version/plaintext stays exact; unavailable/offline reads cannot invent current content',
      () async {
    final f = Fixture(),
        c = client(f),
        m = ProfileLegalController(ContentApi(c.dio), 'TERMS');
    addTearDown(() {
      m.dispose();
      c.close();
    });
    await m.load();
    expect(m.value!.version, 'synthetic-v1');
    expect(m.value!.text, contains('<script>'));
    f.offline = true;
    await m.load();
    expect(m.stale, isTrue);
    expect(m.failure, isNotNull);
    final d = client(Fixture()..expiredLegal = true),
        n = ProfileLegalController(ContentApi(d.dio), 'PRIVACY');
    addTearDown(() {
      n.dispose();
      d.close();
    });
    await n.load();
    expect(n.value, isNull);
  });
  testWidgets(
      '200% profile editor keeps phone read-only and validates name/email; settings describes safe cache clearing',
      (t) async {
    final f = Fixture(), store = MemoryDrafts(), c = client(f);
    late ProfileController m;
    await t.runAsync(() async {
      m = ProfileController(c, store, 'one');
      await m.load();
    });
    await t.pumpWidget(app(m, section: 'edit'));
    await t.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await reveal(t, find.text('Your sign-in mobile is read-only.'));
    expect(find.text('+919000000000'), findsOneWidget);
    await t.enterText(find.byType(TextFormField).first, ' ');
    await reveal(t, find.text('Save profile'));
    await t.tap(find.text('Save profile'));
    await t.pumpAndSettle();
    expect(f.calls.where((o) => o.method == 'PUT'), isEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    c.close();
    final d = client(f);
    late ProfileController n;
    await t.runAsync(() async {
      n = ProfileController(d, store, 'two');
      await n.load();
    });
    await t.pumpWidget(app(n, section: 'settings'));
    await t.pumpAndSettle();
    await reveal(t, find.text('Clear profile cache'));
    await t.tap(find.text('Clear profile cache'));
    await t.pumpAndSettle();
    expect(
        find.textContaining('Pending changes and offline deliveries are kept.'),
        findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    d.close();
  });
  testWidgets(
      'About shows native version, license entry and legal links without deferred menus',
      (t) async {
    await t.pumpWidget(ProviderScope(
        overrides: [
          profileVersionProvider.overrideWith((ref) async => '0.1.0')
        ],
        child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...SbLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProfileAboutPage())));
    await t.pumpAndSettle();
    expect(find.text('Version: 0.1.0'), findsOneWidget);
    expect(find.text('Open-source licenses'), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Payment Methods'), findsNothing);
    expect(find.text('Invite & Earn'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
