import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/orders/orders_controller.dart';
import '../test/features/orders/orders_test.dart'
    show OrdersFixture, ordersClient, ordersApp, orderId, orderPhone;
import '../test/features/addresses/addresses_test.dart' show reveal;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'TC-046/049 Android encrypted transition restart/offline/200% replay/logout',
      (tester) async {
    final dir = await Directory.systemTemp.createTemp('supplybiz-orders-test');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'orders_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        f = OrdersFixture();
    final http = ordersClient(f);
    addTearDown(http.close);
    var m = VendorOrdersController(
        VendorOrdersApi(http.dio), store, 'native:orders');
    await m.load();
    await m.open(orderId);
    f.lost = true;
    await m.act(orderId, 'ACCEPTED');
    final key = m.pending!['key'];
    m.dispose();
    await storage.close();
    await storage.initialize();
    f.offline = true;
    m = VendorOrdersController(
        VendorOrdersApi(http.dio), store, 'native:orders');
    await m.load();
    expect(m.pending!['key'], key);
    expect(m.details[orderId]!.customerMobile, orderPhone);
    expect(m.canActOn(orderId), isFalse);
    f.offline = false;
    await tester.pumpWidget(ordersApp(m, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Retry saved order update'));
    await tester.tap(find.text('Retry saved order update'));
    for (var i = 0; i < 100 && (m.pending != null || m.busy); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(m.pending, isNull);
    expect(f.commits, 1);
    expect(m.details[orderId]!.status, 'ACCEPTED');
    expect(tester.takeException(), isNull);
    expect(await store.read('other:orders'), isEmpty);
    for (final suffix in ['', '-wal']) {
      final file = File('${dir.path}/supplybiz.sqlite$suffix');
      if (await file.exists()) {
        final bytes = String.fromCharCodes(await file.readAsBytes());
        expect(bytes.contains(orderPhone), isFalse);
        expect(bytes.contains('Synthetic order customer'), isFalse);
        expect(bytes.contains(key as String), isFalse);
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await storage.wipeOnLogout();
    await storage.initialize();
    expect(await store.read('native:orders'), isEmpty);
  });
}
