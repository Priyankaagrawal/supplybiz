// T-107 / TC-132: topic/page accuracy, public transport, bounded offline reads and UI.
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
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/features/help/help_controller.dart';
import 'package:supplybiz_mobile/features/help/help_page.dart';
import 'package:supplybiz_mobile/features/profile/profile_controller.dart';
import 'package:supplybiz_mobile/features/profile/profile_pages.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/addresses_test.dart' show reveal;

class Session extends TestSession {
  Session({this.signedIn = true});
  final bool signedIn;
  @override
  String? get accessToken => signedIn ? super.accessToken : null;
  int refreshes = 0, clears = 0;
  @override
  Future<void> refresh() async {
    refreshes++;
  }

  @override
  Future<void> clear({AppFailure? reason}) async {
    clears++;
  }
}

class Fixture implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  List<Map<String, dynamic>> rows = List.generate(2, (i) => row(i));
  bool offline = false, wrongLegal = false;
  int? status;
  Completer<void>? gate, started;
  static Map<String, dynamic> row(int i) => {
        'id': '${i.toString().padLeft(8, '0')}-1111-4111-8111-111111111111',
        'topic': i.isEven ? 'orders' : 'payments',
        'question': 'Question $i about a delivery or account',
        'answer': 'Answer $i: <script>plain text only</script>',
        'published': true,
        'updatedAt': '2026-11-19T01:00:00Z'
      };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    calls.add(o);
    if (gate != null) {
      started?.complete();
      await gate!.future;
    }
    if (offline) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    ResponseBody json(Object v, [int code = 200]) =>
        ResponseBody.fromString(jsonEncode(v), code, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (status != null) return json({'code': 'UNAVAILABLE'}, status!);
    if (o.path.contains('/legal/')) {
      final type = wrongLegal ? 'PRIVACY' : o.path.split('/').last;
      return json({
        'type': type,
        'version': 'synthetic-$type-v1',
        'title': 'Synthetic $type',
        'text': 'Published $type <text>',
        'sha256': 'a' * 64,
        'publishedAt': '2026-11-19T01:00:00Z'
      });
    }
    final topic = o.queryParameters['topic'] as String?,
        offset = o.queryParameters['offset'] as int? ?? 0;
    final selected = rows
        .where((r) =>
            r['published'] == true && (topic == null || r['topic'] == topic))
        .toList();
    return json({
      'items': selected.skip(offset).take(20).toList(),
      'total': selected.length
    });
  }
}

class ReadFailureDrafts extends MemoryDrafts {
  bool readFails = false;
  @override
  Future<Map<String, String>> read(String owner) async {
    if (readFails) throw StateError('Synthetic cache read failure');
    return super.read(owner);
  }
}

(NetworkClient, HelpController) model(Fixture f, MemoryDrafts store,
    {String owner = 'one', Session? session}) {
  final client = NetworkClient(
      baseUrl: 'https://api.example.test',
      adapter: f,
      session: session ?? Session(),
      delay: (_) async {});
  return (client, HelpController(ContentApi(client.dio), store, owner));
}

void cleanup((NetworkClient, HelpController) pair) {
  pair.$2.dispose();
  pair.$1.close();
}

Widget app(HelpController m) => ProviderScope(
    overrides: [helpProvider.overrideWith((ref) => m)],
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
        home: const HelpPage()));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'recovered cache read merges newer memory pages without exceeding the bound',
      () async {
    final f = Fixture(), store = ReadFailureDrafts(), p = model(f, store);
    for (final topic in ['orders', 'payments', 'delivery', 'account', 'kyc']) {
      await p.$2.load(topic: topic, offset: 0);
    }
    cleanup(p);
    store.readFails = true;
    final q = model(f, store);
    addTearDown(() => cleanup(q));
    await q.$2.load(topic: 'general', offset: 0);
    await q.$2.load(topic: 'custom-topic', offset: 0);
    expect(q.$2.cacheUnavailable, isTrue);
    store.readFails = false;
    f.status = 403;
    await q.$2.load(topic: 'denied-topic', offset: 0);
    expect(store.rows['one']!.length, lessThanOrEqualTo(5));
    expect(store.rows['one']!.containsKey('custom-topic:0'), isTrue);
    f.status = null;
    await q.$2.load(all: true);
    expect(q.$2.cacheUnavailable, isFalse);
    expect(q.$2.stale, isFalse);
  });
  test(
      'public generated FAQ requests use exact topic/offset, reset pages on topic change and never mutate/authenticate',
      () async {
    final f = Fixture()..rows = List.generate(45, Fixture.row),
        p = model(f, MemoryDrafts());
    addTearDown(() => cleanup(p));
    final m = p.$2;
    await m.load();
    expect(m.value!.items.length, 20);
    expect(m.value!.total, 45);
    await m.load(offset: 20);
    expect(f.calls.last.queryParameters, {'offset': 20});
    expect(m.value!.items.first.id, Fixture.row(20)['id']);
    await m.load(topic: 'payments', offset: 0);
    expect(f.calls.last.queryParameters, {'offset': 0, 'topic': 'payments'});
    expect(m.value!.items.every((r) => r.topic == 'payments'), isTrue);
    expect(
        f.calls.every((c) =>
            c.method == 'GET' &&
            !c.headers.keys.any((k) => k.toLowerCase() == 'authorization') &&
            c.extra[NetworkClient.publicRequest] == true),
        isTrue);
    final count = f.calls.length;
    await m.load(topic: '../invalid');
    await m.load(offset: -1);
    expect(f.calls.length, count);
  });
  test(
      'cache matches the selected query, survives recreation and is isolated from another owner',
      () async {
    final f = Fixture(), store = MemoryDrafts(), p = model(f, store);
    await p.$2.load();
    await p.$2.load(topic: 'payments', offset: 0);
    f.offline = true;
    await p.$2.load(topic: 'orders', offset: 0);
    expect(p.$2.value, isNull);
    await p.$2.load(all: true);
    expect(p.$2.value!.items.length, 2);
    expect(p.$2.stale, isTrue);
    cleanup(p);
    final q = model(f, store), other = model(f, store, owner: 'other');
    addTearDown(() => cleanup(q));
    addTearDown(() => cleanup(other));
    await q.$2.load();
    expect(q.$2.value!.total, 2);
    await other.$2.load();
    expect(other.$2.value, isNull);
  });
  test(
      'cache stays bounded, write failure keeps fresh reads, and a fresh empty page replaces old published entries',
      () async {
    final f = Fixture(), store = MemoryDrafts(), p = model(f, store);
    addTearDown(() => cleanup(p));
    for (final t in [
      'orders',
      'payments',
      'delivery',
      'account',
      'kyc',
      'general'
    ]) {
      await p.$2.load(topic: t, offset: 0);
    }
    expect(store.rows['one']!.length, 5);
    store.fail = true;
    await p.$2.load(all: true);
    expect(p.$2.stale, isFalse);
    expect(p.$2.cacheUnavailable, isTrue);
    expect(p.$2.value!.total, 2);
    store.fail = false;
    f.rows = [];
    await p.$2.load(all: true);
    expect(p.$2.value!.items, isEmpty);
    expect(p.$2.stale, isFalse);
  });
  test(
      'explicit denial drops the cached query and public 401 never refreshes or logs out the account',
      () async {
    final f = Fixture(),
        store = MemoryDrafts(),
        session = Session(),
        p = model(f, store, session: session);
    addTearDown(() => cleanup(p));
    await p.$2.load();
    f.status = 401;
    await p.$2.load();
    expect(p.$2.value, isNull);
    expect(store.rows['one'], isEmpty);
    expect(session.refreshes, 0);
    expect(session.clears, 0);
  });
  test('late responses cannot publish or persist after disposal', () async {
    final f = Fixture(), store = MemoryDrafts(), p = model(f, store);
    f.gate = Completer<void>();
    f.started = Completer<void>();
    final flight = p.$2.load();
    await f.started!.future;
    p.$2.dispose();
    f.gate!.complete();
    await flight;
    p.$1.close();
    expect(p.$2.value, isNull);
    expect(store.rows, isEmpty);
  });
  test(
      'legal public transport binds the returned document to its selected type',
      () async {
    final f = Fixture()..wrongLegal = true,
        session = Session(),
        client = NetworkClient(
            baseUrl: 'https://api.example.test',
            adapter: f,
            session: session,
            delay: (_) async {}),
        m = ProfileLegalController(ContentApi(client.dio), 'TERMS');
    addTearDown(() {
      m.dispose();
      client.close();
    });
    await m.load();
    expect(m.value, isNull);
    expect(m.failure, isNotNull);
    expect(
        f.calls.single.headers.keys
            .any((k) => k.toLowerCase() == 'authorization'),
        isFalse);
  });
  testWidgets(
      'phone-sized 200% FAQ expands as plaintext; call/email stay disabled with no fabricated contacts',
      (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final f = Fixture();
    late (NetworkClient, HelpController) p;
    await t.runAsync(() async {
      p = model(f, MemoryDrafts());
      await p.$2.load();
    });
    await t.pumpWidget(app(p.$2));
    await t.pumpAndSettle();
    await reveal(t, find.text('Question 0 about a delivery or account'));
    await t.tap(find.text('Question 0 about a delivery or account'));
    await t.pumpAndSettle();
    expect(find.text('Answer 0: <script>plain text only</script>'),
        findsOneWidget);
    expect(t.takeException(), isNull);
    await reveal(t, find.text('Call support'));
    final call =
            t.widget<SbButton>(find.widgetWithText(SbButton, 'Call support')),
        email =
            t.widget<SbButton>(find.widgetWithText(SbButton, 'Email support'));
    expect(call.onPressed, isNull);
    expect(email.onPressed, isNull);
    expect(find.textContaining('have not been published yet'), findsOneWidget);
    expect(f.calls.every((r) => r.method == 'GET'), isTrue);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    p.$1.close();
  });
  testWidgets(
      'common legal reader switches between exact published Terms and Privacy without a session',
      (t) async {
    final f = Fixture(),
        client = NetworkClient(
            baseUrl: 'https://api.example.test',
            adapter: f,
            session: Session(signedIn: false),
            delay: (_) async {}),
        terms = ProfileLegalController(ContentApi(client.dio), 'TERMS'),
        privacy = ProfileLegalController(ContentApi(client.dio), 'PRIVACY');
    await t.runAsync(() async {
      await terms.load();
      await privacy.load();
    });
    await t.pumpWidget(ProviderScope(
        overrides: [
          profileLegalProvider
              .overrideWith((ref, type) => type == 'TERMS' ? terms : privacy)
        ],
        child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...SbLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProfileLegalPage(type: 'TERMS', allowSwitch: true))));
    await t.pumpAndSettle();
    expect(find.text('Published TERMS <text>'), findsOneWidget);
    await t.tap(find.widgetWithText(SbButton, 'Privacy Policy'));
    await t.pumpAndSettle();
    expect(find.text('Published PRIVACY <text>'), findsOneWidget);
    expect(
        find.text('Published version: synthetic-PRIVACY-v1'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    client.close();
  });
}
