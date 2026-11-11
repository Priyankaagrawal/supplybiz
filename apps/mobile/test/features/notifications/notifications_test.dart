import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:supplybiz_mobile/features/notifications/notification_host.dart';
import 'package:supplybiz_mobile/features/notifications/notifications_controller.dart';
import 'package:supplybiz_mobile/features/notifications/notifications_page.dart';
import 'package:supplybiz_mobile/features/notifications/push_gateway.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:ui_kit/ui_kit.dart';

import '../onboarding/onboarding_test.dart' show TestSession, MemoryDrafts;
import 'notification_fixture.dart';

NotificationsController notificationModel(NotificationFixture fixture) {
  final client = NetworkClient(
      baseUrl: 'https://api.example.test',
      session: TestSession(),
      adapter: fixture,
      delay: (_) async {});
  addTearDown(client.close);
  final model =
      NotificationsController(NotificationsApi(client.dio), notificationOwner);
  addTearDown(model.dispose);
  return model;
}

Widget notificationApp(NotificationsController model, FakePushGateway push,
    NotificationSession session,
    {double scale = 1, GoRouter? router, OnboardingDrafts? store}) {
  final routing = router ??
      GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const NotificationsPage())
      ]);
  if (router == null) addTearDown(routing.dispose);
  return ProviderScope(
      overrides: [
        notificationsProvider.overrideWith((ref) => model),
        sessionProvider.overrideWith(() => session),
        pushGatewayProvider.overrideWithValue(push),
        onboardingDraftsProvider.overrideWithValue(store ?? MemoryDrafts()),
      ],
      child: MaterialApp.router(
        routerConfig: routing,
        theme: sbLightTheme(const Locale('en')),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...SbLocalizations.delegates
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: NotificationHost(router: routing, child: child!)),
      ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('TC-100/101 role/category pagination, replay and persisted read/clear',
      () async {
    final fixture = NotificationFixture();
    for (int i = 0; i < 101; i++) {
      fixture.rows.add(notificationJson(id: 'synthetic-$i'));
    }
    fixture.rows.add(notificationJson(role: 'VENDOR', category: 'SYSTEM'));
    final model = notificationModel(fixture);
    expect(await model.load('CUSTOMER'), isTrue);
    expect(model.items, hasLength(102));
    expect(await model.load('CUSTOMER', 'SYSTEM'), isTrue);
    expect(model.items, isEmpty);
    expect(model.unread, 102);
    await model.load('CUSTOMER');
    fixture.loseResponse = true;
    expect(await model.read('CUSTOMER'), isFalse);
    expect(model.hasPending, isTrue);
    final key = fixture.calls.last.headers['Idempotency-Key'];
    expect(await model.retry(), isTrue);
    expect(
        fixture.calls
            .where((c) => c.uri.path.endsWith('/read'))
            .last
            .headers['Idempotency-Key'],
        key);
    expect(model.unread, 0);
    expect(await model.clear(), isTrue);
    expect(model.items, isEmpty);
    expect(fixture.rows.single['role'], 'VENDOR');
  });
  test('TC-102 preferences, device opt-out and denial purge', () async {
    final fixture = NotificationFixture(),
        model = notificationModel(NotificationFixture());
    final owned = notificationModel(fixture);
    await owned.load('CUSTOMER');
    await owned.save(NotificationPreferences(
        orders: false, payments: true, delivery: true, system: false));
    expect(owned.preferences!.orders, isFalse);
    await owned.register(null);
    expect(fixture.calls.last.data, contains('"pushEnabled":false'));
    fixture.denial = 403;
    await owned.load('CUSTOMER');
    expect(owned.items, isEmpty);
    expect(owned.preferences, isNull);
    expect(await model.find('malicious', 'ADMIN'), isNull);
  });
  test(
      'TC-104 owned lookup excludes other roles and drops late disposed responses',
      () async {
    final fixture = NotificationFixture(),
        model = notificationModel(NotificationFixture());
    expect(await model.find(notificationId, 'VENDOR'), isNull);
    fixture.gate = Completer<void>();
    final stale = notificationModel(fixture);
    final future = stale.find(notificationId, 'CUSTOMER');
    await Future<void>.delayed(Duration.zero);
    stale.dispose();
    fixture.gate!.complete();
    expect(await future, isNull);
  });
  test(
      'TC-104 paths allow only implemented destinations and normalize subscriptions',
      () {
    InboxItem row(String path, {String role = 'CUSTOMER'}) =>
        InboxItem.fromJson(notificationJson(role: role)..['path'] = path);
    expect(
        notificationLocation(
            row('https://malicious.test/customer/orders/$notificationId')),
        '/common/notifications');
    expect(notificationLocation(row('/vendor/orders/$notificationId')),
        '/common/notifications');
    expect(
        notificationLocation(
            row('/customer/orders/$notificationId?role=VENDOR')),
        '/common/notifications');
    expect(notificationLocation(row('/customer/subscriptions/$notificationId')),
        '/customer/orders/subscriptions/$notificationId');
    expect(
        notificationLocation(row('/vendor/onboarding/status', role: 'VENDOR')),
        '/vendor/onboarding/status');
  });
  testWidgets('TC-100/102 Android pre-prompt only after action; 200% layout',
      (tester) async {
    final fixture = NotificationFixture(),
        model = notificationModel(NotificationFixture());
    final push = FakePushGateway();
    addTearDown(push.close);
    await tester.runAsync(() => model.load('CUSTOMER'));
    await tester.pumpWidget(
        notificationApp(model, push, NotificationSession(), scale: 2));
    await tester.pumpAndSettle();
    expect(push.prompts, 0);
    expect(find.text('Delivery'), findsNothing);
    await tester.scrollUntilVisible(find.text('Enable push alerts'), 400);
    await tester.ensureVisible(find.text('Enable push alerts'));
    await tester.tap(find.text('Enable push alerts'));
    await tester.pumpAndSettle();
    expect(push.prompts, 0);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(push.prompts, 1);
    expect(find.textContaining('Alerts are blocked.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(fixture.calls, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-104 warm push ignores spoofed path and confirms held role before read/navigation',
      (tester) async {
    final fixture = NotificationFixture(),
        push = FakePushGateway(),
        session = NotificationSession()..role = 'VENDOR';
    final model = notificationModel(fixture);
    addTearDown(push.close);
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Synthetic home'))),
      GoRoute(
          path: '/customer/orders/:id',
          builder: (_, __) => const Scaffold(body: Text('Owned order'))),
    ]);
    addTearDown(router.dispose);
    await tester
        .pumpWidget(notificationApp(model, push, session, router: router));
    await tester.pumpAndSettle();
    push.taps.add({
      'notificationId': notificationId,
      'role': 'CUSTOMER',
      'path': 'https://malicious.test'
    });
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Switch to Customer to open this notification?'),
        findsOneWidget);
    expect(fixture.rows.single['readAt'], isNull);
    await tester.tap(find.text('Continue'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(session.role, 'CUSTOMER');
    expect(fixture.rows.single['readAt'], isNotNull);
    expect(find.text('Owned order'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-104 cold start resolves owned item without requesting permission',
      (tester) async {
    final fixture = NotificationFixture(),
        push = FakePushGateway()
          ..cold = {
            'notificationId': notificationId,
            'role': 'CUSTOMER',
            'path': '/common/settings'
          };
    final model = notificationModel(fixture);
    addTearDown(push.close);
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Synthetic home'))),
      GoRoute(
          path: '/customer/orders/:id',
          builder: (_, __) => const Scaffold(body: Text('Owned cold order'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(
        notificationApp(model, push, NotificationSession(), router: router));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Owned cold order'), findsOneWidget);
    expect(push.prompts, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-104 logout while role confirmation is open prevents read and navigation',
      (tester) async {
    final fixture = NotificationFixture(),
        push = FakePushGateway(),
        session = NotificationSession()..role = 'VENDOR';
    final model = notificationModel(fixture);
    addTearDown(push.close);
    await tester.pumpWidget(notificationApp(model, push, session));
    await tester.pumpAndSettle();
    push.taps.add({'notificationId': notificationId, 'role': 'CUSTOMER'});
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Switch to Customer to open this notification?'),
        findsOneWidget);
    session.signOut();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(fixture.calls.where((c) => c.uri.path.endsWith('/read')), isEmpty);
    expect(fixture.rows.single['readAt'], isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
