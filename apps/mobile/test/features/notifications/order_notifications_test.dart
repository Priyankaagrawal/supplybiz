import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:supplybiz_mobile/features/notifications/notification_host.dart';
import 'package:supplybiz_mobile/features/notifications/order_notices.dart';
import 'package:supplybiz_mobile/features/notifications/push_gateway.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/orders/orders_controller.dart';
import 'package:supplybiz_mobile/features/orders/orders_pages.dart';
import 'package:supplybiz_mobile/features/orders/customer_orders_controller.dart';
import 'package:supplybiz_mobile/features/orders/customer_orders_pages.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_fixture.dart' show testAuthConfig;
import '../onboarding/onboarding_test.dart' show MemoryDrafts;
import '../orders/orders_test.dart' show OrdersFixture, orderId;
import '../orders/customer_orders_test.dart' show CustomerOrdersFixture;
import 'notification_fixture.dart';

/// Synthetic transport with real repositories, controllers and order pages.
class OrderPushFixture implements HttpClientAdapter {
  final inbox = NotificationFixture();
  final customer = CustomerOrdersFixture();
  final vendor = OrdersFixture();
  void notice(String type, String role, {String id = notificationId}) {
    inbox.rows
      ..clear()
      ..add(notificationJson(id: id, role: role)
        ..['type'] = type
        ..['path'] = '/${role.toLowerCase()}/orders/$orderId');
  }

  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions r, Stream<Uint8List>? s, Future<void>? c) {
    if (r.path.contains('/vendor/orders')) return vendor.fetch(r, s, c);
    if (r.path.contains('/customer/orders')) return customer.fetch(r, s, c);
    return inbox.fetch(r, s, c);
  }
}

Widget orderPushApp(OrderPushFixture fixture, FakePushGateway push,
        NotificationSession session, GoRouter router,
        {OnboardingDrafts? store, double scale = 1}) =>
    ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => session),
          authConfigProvider.overrideWithValue(testAuthConfig),
          authAdapterProvider.overrideWithValue(fixture),
          onboardingDraftsProvider.overrideWithValue(store ?? MemoryDrafts()),
          pushGatewayProvider.overrideWithValue(push),
        ],
        child: MaterialApp.router(
            routerConfig: router,
            theme: sbLightTheme(const Locale('en')),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...SbLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: NotificationHost(router: router, child: child!))));

GoRouter orderPushRouter() => GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Synthetic home'))),
      GoRoute(
          path: '/customer/orders/:id',
          builder: (_, state) =>
              CustomerOrderPage(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/vendor/orders/:id',
          builder: (_, state) =>
              VendorOrderPage(id: state.pathParameters['id']!)),
    ]);
Future<void> settleOrderPush(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'T-052 TC-103 all seven owned order types require a canonical same-role order path',
      () {
    final f = OrderPushFixture();
    for (final role in ['VENDOR', 'CUSTOMER']) {
      final types = role == 'VENDOR'
          ? ['ORDER_NEW', 'ORDER_CANCELLED']
          : [
              'ORDER_ACCEPTED',
              'ORDER_REJECTED',
              'OUT_FOR_DELIVERY',
              'ORDER_DELIVERED',
              'DELIVERY_FAILED'
            ];
      for (final type in types) {
        f.notice(type, role);
        final notice = ownedOrderNotice(
            InboxItem.fromJson(f.inbox.rows.single), notificationOwner);
        expect(notice?.orderId, orderId);
        expect(notice?.role, role);
      }
    }
    for (final path in [
      'https://malicious.test/customer/orders/$orderId',
      '/vendor/orders/$orderId',
      '/customer/orders/$orderId?role=VENDOR'
    ]) {
      f.notice('OUT_FOR_DELIVERY', 'CUSTOMER');
      f.inbox.rows.single['path'] = path;
      expect(
          ownedOrderNotice(
              InboxItem.fromJson(f.inbox.rows.single), notificationOwner),
          isNull);
    }
    f.notice('ORDER_NEW', 'CUSTOMER');
    expect(
        ownedOrderNotice(
            InboxItem.fromJson(f.inbox.rows.single), notificationOwner),
        isNull);
  });
  testWidgets(
      'T-052 TC-103 owned Out for Delivery refreshes an active customer view; duplicate/spoofed notices never mutate it',
      (tester) async {
    final f = OrderPushFixture()..notice('OUT_FOR_DELIVERY', 'CUSTOMER'),
        push = FakePushGateway(),
        router = orderPushRouter();
    addTearDown(push.close);
    addTearDown(router.dispose);
    await tester
        .pumpWidget(orderPushApp(f, push, NotificationSession(), router));
    await settleOrderPush(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(NotificationHost)));
    final model = container.read(customerOrdersProvider);
    await tester.runAsync(() async {
      await model.load();
      await model.open(orderId);
    });
    f.customer.rows.first['status'] = 'OUT_FOR_DELIVERY';
    push.messages.add({
      'notificationId': notificationId,
      'role': 'CUSTOMER',
      'type': 'ORDER_NEW',
      'path': '/vendor/orders/$orderId'
    });
    await settleOrderPush(tester);
    expect(model.details[orderId]!.status, 'OUT_FOR_DELIVERY');
    final reads = f.customer.requests.length;
    push.messages.add({'notificationId': notificationId, 'role': 'CUSTOMER'});
    await settleOrderPush(tester);
    expect(f.customer.requests.length, reads);
    push.messages.add({
      'notificationId': '33333333-3333-4333-8333-333333333333',
      'role': 'CUSTOMER',
      'type': 'ORDER_DELIVERED'
    });
    await settleOrderPush(tester);
    expect(f.customer.requests.length, reads);
    expect(f.customer.commits, 0);
    expect(router.routeInformationProvider.value.uri.path, '/');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'T-052 TC-103 vendor new/cancelled notices refresh owned active detail and list',
      (tester) async {
    final f = OrderPushFixture()..notice('ORDER_NEW', 'VENDOR'),
        push = FakePushGateway(),
        router = orderPushRouter();
    addTearDown(push.close);
    addTearDown(router.dispose);
    await tester.pumpWidget(
        orderPushApp(f, push, NotificationSession()..role = 'VENDOR', router));
    await settleOrderPush(tester);
    final container = ProviderScope.containerOf(
            tester.element(find.byType(NotificationHost))),
        model = container.read(vendorOrdersProvider);
    await tester.runAsync(() async {
      await model.load();
      await model.open(orderId);
    });
    push.messages.add({'notificationId': notificationId, 'role': 'VENDOR'});
    await settleOrderPush(tester);
    final reads = f.vendor.requests.length;
    f.vendor.rows.first['status'] = 'CANCELLED';
    const next = '33333333-3333-4333-8333-333333333333';
    f.notice('ORDER_CANCELLED', 'VENDOR', id: next);
    push.messages.add({'notificationId': next, 'role': 'VENDOR'});
    await settleOrderPush(tester);
    expect(model.details[orderId]!.status, 'CANCELLED');
    expect(f.vendor.requests.length, greaterThan(reads));
    expect(f.vendor.commits, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'T-052 TC-104 cold customer notice confirms role then opens the real owned order page at 200%',
      (tester) async {
    final f = OrderPushFixture()..notice('ORDER_ACCEPTED', 'CUSTOMER'),
        push = FakePushGateway()
          ..cold = {
            'notificationId': notificationId,
            'role': 'CUSTOMER',
            'path': 'https://malicious.test'
          },
        router = orderPushRouter(),
        session = NotificationSession()..role = 'VENDOR';
    addTearDown(push.close);
    addTearDown(router.dispose);
    await tester.pumpWidget(orderPushApp(f, push, session, router, scale: 2));
    await settleOrderPush(tester);
    await settleOrderPush(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(NotificationHost)));
    expect(container.exists(customerOrdersProvider), isFalse);
    expect(find.text('Switch to Customer to open this notification?'),
        findsOneWidget);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await settleOrderPush(tester);
    expect(session.role, 'CUSTOMER');
    expect(router.routeInformationProvider.value.uri.path,
        '/customer/orders/$orderId');
    expect(find.byType(CustomerOrderPage), findsOneWidget);
    expect(find.text('ORD00000001'), findsWidgets);
    expect(push.prompts, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'T-052 TC-104 warm vendor notice confirms role and opens real vendor detail',
      (tester) async {
    final f = OrderPushFixture()..notice('ORDER_NEW', 'VENDOR'),
        push = FakePushGateway(),
        router = orderPushRouter(),
        session = NotificationSession();
    addTearDown(push.close);
    addTearDown(router.dispose);
    await tester.pumpWidget(orderPushApp(f, push, session, router));
    await settleOrderPush(tester);
    push.taps.add({
      'notificationId': notificationId,
      'role': 'VENDOR',
      'path': '/common/settings'
    });
    await settleOrderPush(tester);
    expect(session.role, 'CUSTOMER');
    expect(find.text('Switch to Vendor to open this notification?'),
        findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settleOrderPush(tester);
    expect(session.role, 'VENDOR');
    expect(find.byType(VendorOrderPage), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path,
        '/vendor/orders/$orderId');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
