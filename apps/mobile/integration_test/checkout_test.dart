import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/discovery/cart_controller.dart';
import 'package:supplybiz_mobile/features/checkout/checkout_controller.dart';
import '../test/features/checkout/checkout_test.dart'
    show CheckoutFixture, checkoutClient, checkoutCart, checkoutApp;
import '../test/features/addresses/addresses_test.dart' show reveal;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'TC-227 Android encrypted order retry/restored cart lock/200% confirmation/logout',
      (tester) async {
    final dir =
        await Directory.systemTemp.createTemp('supplybiz-checkout-test');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'checkout_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        f = CheckoutFixture();
    final live = checkoutClient(f);
    addTearDown(live.close);
    var cart = await checkoutCart(store, owner: 'native:cart');
    var m = CheckoutController(CustomerOrdersApi(live.dio),
        CustomerAddressesApi(live.dio), cart, store, 'native:checkout');
    await m.load();
    await m.refreshQuote();
    f.lost = true;
    await m.place();
    final key = m.pending!['key'];
    m.dispose();
    cart.dispose();
    await storage.close();
    await storage.initialize();
    cart = CartController(store, 'native:cart');
    await cart.load();
    expect(cart.checkoutLocked, isTrue);
    m = CheckoutController(CustomerOrdersApi(live.dio),
        CustomerAddressesApi(live.dio), cart, store, 'native:checkout');
    await m.load();
    expect(m.pending!['key'], key);
    await tester.pumpWidget(checkoutApp(m, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Retry saved order'));
    await tester.tap(find.text('Retry saved order'));
    for (var i = 0; i < 100 && m.result == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(m.result?.orderNo, 'ORD00000001');
    expect(f.commits, 1);
    expect(cart.lines, isEmpty);
    expect(await store.read('another:checkout'), isEmpty);
    expect(tester.takeException(), isNull);
    for (final suffix in ['', '-wal']) {
      final file = File('${dir.path}/supplybiz.sqlite$suffix');
      if (await file.exists()) {
        final bytes = String.fromCharCodes(await file.readAsBytes());
        expect(bytes.contains(key as String), isFalse);
        expect(bytes.contains('ORD00000001'), isFalse);
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await storage.wipeOnLogout();
    await storage.initialize();
    expect(await store.read('native:checkout'), isEmpty);
  });
}
