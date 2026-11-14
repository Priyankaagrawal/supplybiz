// T-052 / TC-103–104: native Android pages/storage; HTTP and FCM are simulated.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/notifications/notification_host.dart';
import 'package:supplybiz_mobile/features/orders/customer_orders_controller.dart';
import 'package:supplybiz_mobile/features/orders/customer_orders_pages.dart';
import 'package:supplybiz_mobile/features/orders/orders_controller.dart';
import 'package:supplybiz_mobile/features/orders/orders_pages.dart';
import '../test/features/auth/auth_fixture.dart' show testAuthConfig;
import '../test/features/orders/orders_test.dart' show orderId;
import '../test/features/notifications/notification_fixture.dart';
import '../test/features/notifications/order_notifications_test.dart'
    show OrderPushFixture, orderPushApp, orderPushRouter, settleOrderPush;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-052 TC-103/104 Android cold/warm role-confirmed order pages, trusted refresh, SQLCipher and 200%',
      (tester) async {
    Future<void> until(bool Function() ready) async {
      for (var i = 0; i < 100 && !ready(); i++) {
        await settleOrderPush(tester);
      }
      expect(ready(), isTrue,
          reason: 'Native async navigation/cache did not finish.');
    }

    final dir =
        await Directory.systemTemp.createTemp('supplybiz-order-notices-test');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 't052-order-notices'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        f = OrderPushFixture()..notice('ORDER_ACCEPTED', 'CUSTOMER'),
        push = FakePushGateway()
          ..cold = {
            'notificationId': notificationId,
            'role': 'CUSTOMER',
            'path': 'https://malicious.test'
          },
        session = NotificationSession()..role = 'VENDOR',
        router = orderPushRouter();
    addTearDown(push.close);
    addTearDown(router.dispose);
    await tester.pumpWidget(
        orderPushApp(f, push, session, router, store: store, scale: 2));
    await settleOrderPush(tester);
    await settleOrderPush(tester);
    expect(find.text('Switch to Customer to open this notification?'),
        findsOneWidget);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await settleOrderPush(tester);
    await until(() => find.byType(CustomerOrderPage).evaluate().isNotEmpty);
    expect(session.role, 'CUSTOMER');
    expect(find.byType(CustomerOrderPage), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path,
        '/customer/orders/$orderId');
    final container = ProviderScope.containerOf(
            tester.element(find.byType(NotificationHost))),
        customer = container.read(customerOrdersProvider);
    await until(() => !customer.busy && customer.details.containsKey(orderId));
    const next = '33333333-3333-4333-8333-333333333333';
    f.customer.rows.first['status'] = 'OUT_FOR_DELIVERY';
    f.notice('OUT_FOR_DELIVERY', 'CUSTOMER', id: next);
    push.messages.add({
      'notificationId': next,
      'role': 'CUSTOMER',
      'type': 'ORDER_NEW',
      'path': '/vendor/orders/$orderId'
    });
    await settleOrderPush(tester);
    await until(() =>
        !customer.busy &&
        customer.details[orderId]?.status == 'OUT_FOR_DELIVERY');
    expect(customer.details[orderId]!.status, 'OUT_FOR_DELIVERY');
    final saved = await store
        .read('${testAuthConfig.baseUrl}:$notificationOwner:customer-orders');
    final details = jsonDecode(saved['details']!) as List;
    expect(details.where((d) => d['id'] == orderId).single['status'],
        'OUT_FOR_DELIVERY');
    const vendorNotice = '44444444-4444-4444-8444-444444444444';
    f.vendor.rows.first['status'] = 'CANCELLED';
    f.notice('ORDER_CANCELLED', 'VENDOR', id: vendorNotice);
    push.taps.add({
      'notificationId': vendorNotice,
      'role': 'VENDOR',
      'path': '/common/settings'
    });
    await settleOrderPush(tester);
    await until(() => find
        .text('Switch to Vendor to open this notification?')
        .evaluate()
        .isNotEmpty);
    expect(find.text('Switch to Vendor to open this notification?'),
        findsOneWidget);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await settleOrderPush(tester);
    await until(() => find.byType(VendorOrderPage).evaluate().isNotEmpty);
    await until(() =>
        container.read(vendorOrdersProvider).details[orderId]?.status ==
        'CANCELLED');
    expect(session.role, 'VENDOR');
    expect(find.byType(VendorOrderPage), findsOneWidget);
    expect(container.read(vendorOrdersProvider).details[orderId]!.status,
        'CANCELLED');
    expect(push.prompts, 0);
    expect(f.customer.commits, 0);
    expect(f.vendor.commits, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final bytes = await File('${dir.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(bytes).contains('ORD00000001'), isFalse);
    await storage.wipeOnLogout();
    await storage.initialize();
    expect(
        await store.read(
            '${testAuthConfig.baseUrl}:$notificationOwner:customer-orders'),
        isEmpty);
  });
}
