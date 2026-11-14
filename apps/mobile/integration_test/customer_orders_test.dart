import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/orders/customer_orders_controller.dart';
import '../test/features/orders/customer_orders_test.dart'
    show CustomerOrdersFixture, customerOrdersApp;
import '../test/features/orders/orders_test.dart'
    show ordersClient, orderId, orderPhone;
import '../test/features/addresses/addresses_test.dart' show reveal;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'TC-241/242 Android encrypted customer order restart/cancel retry/200%/logout',
      (tester) async {
    final dir =
        await Directory.systemTemp.createTemp('supplybiz-customer-orders-test');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'customer_orders_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        f = CustomerOrdersFixture(),
        http = ordersClient(f);
    addTearDown(http.close);
    var m = CustomerOrdersController(
        CustomerOrdersApi(http.dio), store, 'native:customer-orders');
    await m.load();
    await m.open(orderId);
    f.lost = true;
    await m.cancel(orderId);
    final key = m.pending!['key'];
    m.dispose();
    await storage.close();
    await storage.initialize();
    f.offline = true;
    m = CustomerOrdersController(
        CustomerOrdersApi(http.dio), store, 'native:customer-orders');
    await m.load();
    expect(m.pending!['key'], key);
    expect(m.details[orderId]!.vendorMobile, orderPhone);
    expect(m.canActOn(orderId), isFalse);
    f.offline = false;
    await tester.pumpWidget(customerOrdersApp(m, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Retry saved order update'));
    await tester.tap(find.text('Retry saved order update'));
    for (var i = 0; i < 100 && (m.pending != null || m.busy); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(m.pending, isNull);
    expect(f.commits, 1);
    expect(m.details[orderId]!.status, 'CANCELLED');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final raw = await File('${dir.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(raw).contains(orderPhone), isFalse);
    await storage.wipeOnLogout();
    await storage.initialize();
    expect((await store.read('native:customer-orders')), isEmpty);
  });
}
