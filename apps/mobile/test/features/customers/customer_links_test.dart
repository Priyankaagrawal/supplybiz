// T-053 / TC-064: fixture HTTP, real controller/provider/UI consent paths.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:supplybiz_mobile/features/customers/customer_links_controller.dart';
import 'package:supplybiz_mobile/features/customers/customer_links_prompt.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import '../auth/auth_fixture.dart';
import '../home/home_fixture.dart';
import '../notifications/notification_fixture.dart' show NotificationSession;
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;

const linkId = '22222222-2222-4222-8222-222222222222';
Map<String, Object?> linkJson([String id = linkId]) => {
      'id': id,
      'vendorId': '33333333-3333-4333-8333-333333333333',
      'businessName': 'Synthetic vendor',
    };

class LinkFixture implements HttpClientAdapter {
  final rows = <Map<String, Object?>>[linkJson()];
  final calls = <RequestOptions>[];
  final decisions = <String, String>{};
  final keys = <String>[];
  final home = HomeFixture();
  bool offline = false, loseResponse = false, failNextList = false;
  int? denial;
  Completer<void>? gate;
  void Function()? committed;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions r, Stream<Uint8List>? stream, Future<void>? cancel) async {
    if (!r.uri.path.contains('/link-requests')) {
      return home.fetch(r, stream, cancel);
    }
    calls.add(r);
    ResponseBody reply(Object body, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(body), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: r, type: DioExceptionType.connectionError);
    }
    if (denial != null) {
      return reply({'code': 'LINK_REQUEST_NOT_FOUND'}, denial!);
    }
    await gate?.future;
    if (r.method == 'GET') {
      if (failNextList) return reply({'code': 'SYNTHETIC_UNAVAILABLE'}, 503);
      final offset = r.queryParameters['offset'] as int? ?? 0;
      final limit = r.queryParameters['limit'] as int? ?? 50;
      return reply({
        'items': rows.skip(offset).take(limit).toList(),
        'total': rows.length
      });
    }
    final segments = r.uri.pathSegments,
        id = segments[segments.length - 2],
        action = segments.last;
    keys.add(r.headers['Idempotency-Key'] as String);
    final decision = action == 'accept' ? 'ACCEPTED' : 'DECLINED';
    if (decisions[id] != null && decisions[id] != decision) {
      return reply({'code': 'LINK_ALREADY_DECIDED'}, 409);
    }
    decisions[id] = decision;
    rows.removeWhere((row) => row['id'] == id);
    committed?.call();
    if (loseResponse) {
      loseResponse = false;
      throw DioException(
          requestOptions: r, type: DioExceptionType.connectionError);
    }
    return reply({'id': id, 'decision': decision}, 201);
  }
}

CustomerLinksController linkModel(LinkFixture fixture, OnboardingDrafts store,
    {String owner = 'synthetic:links'}) {
  final client = NetworkClient(
      baseUrl: 'https://api.example.test',
      session: TestSession(),
      adapter: fixture,
      delay: (_) async {});
  addTearDown(client.close);
  final model = CustomerLinksController(client, store, owner);
  addTearDown(model.dispose);
  return model;
}

Widget linkApp(LinkFixture fixture, OnboardingDrafts store,
        NotificationSession session, {double scale = 1}) =>
    ProviderScope(
        overrides: [
          authConfigProvider.overrideWithValue(testAuthConfig),
          authAdapterProvider.overrideWithValue(fixture),
          sessionProvider.overrideWith(() => session),
          onboardingDraftsProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...SbLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: const Scaffold(
                body: SafeArea(
                    child:
                        SingleChildScrollView(child: CustomerLinksPrompt())))));
Future<void> settleLinks(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'S-C-38 localized loading state disables refresh until owned requests arrive',
      (tester) async {
    final gate = Completer<void>(), f = LinkFixture()..gate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.pumpWidget(linkApp(f, MemoryDrafts(), NotificationSession()));
    await settleLinks(tester);
    expect(find.byType(SbSkeleton), findsOneWidget);
    expect(
        tester
            .widget<SbButton>(
                find.widgetWithText(SbButton, 'Refresh account links'))
            .onPressed,
        isNull);
    expect(f.keys, isEmpty);
    gate.complete();
    await settleLinks(tester);
    expect(find.text('Synthetic vendor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test(
      'TC-064 fetch/pagination, explicit accept/decline only; no automatic mutation',
      () async {
    final f = LinkFixture()
          ..rows.addAll(List.generate(
              50,
              (i) => linkJson(
                  '11111111-1111-4111-8111-${(i + 1).toString().padLeft(12, '0')}'))),
        m = linkModel(f, MemoryDrafts());
    await m.load();
    expect(m.requests.length, 50);
    expect(f.keys, isEmpty);
    await m.more();
    expect(m.requests.length, 51);
    await m.decide(linkId, true);
    expect(m.completed, 'ACCEPTED');
    expect(m.requests.length, 50);
    await m.decide(m.requests.first.id, false);
    expect(m.completed, 'DECLINED');
    expect(f.decisions.values.toSet(), {'ACCEPTED', 'DECLINED'});
    await m.decide('unowned', true);
    expect(f.keys.length, 2);
  });
  test(
      'TC-064 lost response restores exact choice/key across restart and isolates account',
      () async {
    final f = LinkFixture(), store = MemoryDrafts(), m = linkModel(f, store);
    await m.load();
    f.loseResponse = true;
    await m.decide(linkId, true);
    expect(m.pending, isNotNull);
    expect(m.completed, isNull);
    expect(m.canDecide, false);
    final oldKey = f.keys.single;
    final other = linkModel(f, store, owner: 'other:links');
    await other.load();
    expect(other.pending, isNull);
    final restored = linkModel(f, store);
    await restored.load();
    expect(restored.pending!['action'], 'accept');
    expect(restored.requests, isEmpty);
    await restored.retryPending();
    expect(f.keys, [oldKey, oldKey]);
    expect(restored.completed, 'ACCEPTED');
    expect(restored.pending, isNull);
    expect(f.decisions.length, 1);
    expect(store.rows['synthetic:links'], isEmpty);
  });
  test(
      'TC-064 persist before send and acknowledgement failure fence new decisions',
      () async {
    final f = LinkFixture(), store = MemoryDrafts(), m = linkModel(f, store);
    await m.load();
    store.fail = true;
    await m.decide(linkId, false);
    expect(f.keys, isEmpty);
    expect(m.pending!['action'], 'decline');
    store.fail = false;
    f.committed = () => store.fail = true;
    await m.retryPending();
    expect(m.pending, isNotNull);
    expect(m.canDecide, false);
    final key = f.keys.single;
    store.fail = false;
    f.committed = null;
    await m.retryPending();
    expect(f.keys, [key, key]);
    expect(m.completed, 'DECLINED');
  });
  test(
      'TC-064 stale/denied requests disable choices and definitive conflict clears retry',
      () async {
    final f = LinkFixture(), m = linkModel(f, MemoryDrafts());
    await m.load();
    f.offline = true;
    await m.load();
    expect(m.canDecide, false);
    await m.decide(linkId, true);
    expect(f.keys, isEmpty);
    f.offline = false;
    await m.load();
    f.denial = 409;
    await m.decide(linkId, true);
    expect(m.pending, isNull);
    expect(m.stale, true);
    f.denial = 403;
    await m.load();
    expect(m.requests, isEmpty);
    expect(m.ready, false);
  });
  test(
      'TC-064 post-commit refresh failure cannot resubmit acknowledged decision',
      () async {
    final f = LinkFixture(), m = linkModel(f, MemoryDrafts());
    await m.load();
    f.failNextList = true;
    await m.decide(linkId, true);
    expect(m.completed, 'ACCEPTED');
    expect(m.pending, isNull);
    expect(m.requests, isEmpty);
    expect(m.failure, isNotNull);
    await m.retryPending();
    expect(f.keys.length, 1);
  });
  testWidgets(
      'S-C-38 200% consent cancel/confirm, fallback vendor name and empty state',
      (tester) async {
    final f = LinkFixture()..rows.single['businessName'] = null;
    await tester.pumpWidget(
        linkApp(f, MemoryDrafts(), NotificationSession(), scale: 2));
    await settleLinks(tester);
    expect(find.text('Vendor'), findsOneWidget);
    await tester.ensureVisible(find.text('Decline link'));
    await tester.tap(find.text('Decline link'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(f.keys, isEmpty);
    await tester.ensureVisible(find.text('Link account'));
    await tester.tap(find.text('Link account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('existing customer records'), findsOneWidget);
    await tester.ensureVisible(find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await settleLinks(tester);
    expect(find.text('Account linked.'), findsOneWidget);
    expect(
        find.text('No vendor accounts waiting to be linked.'), findsOneWidget);
    expect(f.decisions[linkId], 'ACCEPTED');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'TC-064 opposite-role/logout confirmation cannot mutate replacement session',
      (tester) async {
    final f = LinkFixture(), session = NotificationSession();
    await tester.pumpWidget(linkApp(f, MemoryDrafts(), session));
    await settleLinks(tester);
    await tester.tap(find.text('Link account'));
    await tester.pumpAndSettle();
    await session.selectRole('VENDOR');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await settleLinks(tester);
    expect(f.keys, isEmpty);
    session.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Link vendor accounts'), findsNothing);
  });
}
