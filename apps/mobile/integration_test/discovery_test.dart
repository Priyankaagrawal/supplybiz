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
import 'package:supplybiz_mobile/features/discovery/favorites_controller.dart';
import 'package:supplybiz_mobile/features/discovery/discovery_controller.dart';
import '../test/features/discovery/discovery_fixture.dart';
import '../test/features/discovery/discovery_test.dart'
    show discoveryClient, discoveryApp;
import '../test/features/home/home_test.dart' show manualLocation;
import '../test/features/addresses/addresses_test.dart' show reveal;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'TC-206–209 Android encrypted cart/favorite replay survives restart; MOQ/add at 200%',
      (tester) async {
    final dir =
        await Directory.systemTemp.createTemp('supplybiz-discovery-test');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'discovery_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        fixture = DiscoveryFixture(),
        client = discoveryClient(fixture);
    addTearDown(client.close);
    final api = DiscoveryApi(client.dio);
    var cart = CartController(store, 'synthetic:cart'),
        favorites = FavoritesController(
            api, store, 'synthetic:favorites', manualLocation);
    await cart.load();
    await favorites.load();
    expect(
        await cart.add(vendorId, 'Synthetic discovery vendor',
            ProductResponse.fromJson(fixture.product), 2),
        CartChange.saved);
    fixture.loseResponse = true;
    await favorites.set(vendorId, true);
    expect(favorites.pending, isNotNull);
    final key = favorites.pending!['key'];
    cart.dispose();
    favorites.dispose();
    await storage.close();
    await storage.initialize();
    cart = CartController(store, 'synthetic:cart');
    favorites =
        FavoritesController(api, store, 'synthetic:favorites', manualLocation);
    await cart.load();
    await favorites.load();
    expect(cart.count, 2);
    expect(favorites.pending!['key'], key);
    await favorites.retry();
    expect(favorites.pending, isNull);
    expect(fixture.commits, 1);
    expect(await store.read('other:cart'), isEmpty);
    for (final suffix in ['', '-wal']) {
      final file = File('${dir.path}/supplybiz.sqlite$suffix');
      if (await file.exists()) {
        final bytes = String.fromCharCodes(await file.readAsBytes());
        expect(bytes.contains('Synthetic discovery vendor'), isFalse);
        expect(bytes.contains(key as String), isFalse);
      }
    }
    final vendor = VendorController(api, manualLocation, vendorId);
    await tester.pumpWidget(discoveryApp(
        cart: cart, favorites: favorites, vendor: vendor, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Quantity: 2'));
    await reveal(tester, find.text('Add to cart'));
    await tester.tap(find.text('Add to cart'));
    for (var attempt = 0; attempt < 80 && cart.count != 4; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(cart.count, 4);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await storage.wipeOnLogout();
    await storage.initialize();
    expect(await store.read('synthetic:cart'), isEmpty);
    expect(await store.read('synthetic:favorites'), isEmpty);
  });
}
