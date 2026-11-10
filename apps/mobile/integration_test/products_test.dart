import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/products/products_controller.dart';

import '../test/features/onboarding/onboarding_test.dart' show TestSession;
import '../test/features/products/catalog_fixture.dart';
import '../test/features/products/products_test.dart' show productApp;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-027 Android encrypted catalog/retry recovery and read-only 200% screen (simulated API)',
      (tester) async {
    final root = await getApplicationSupportDirectory();
    final directory = await Directory('${root.path}/products-test').create();
    const secrets = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'products_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: secrets),
        directory: () async => directory);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        fixture = CatalogFixture();
    final client = NetworkClient(
        baseUrl: 'https://api.example.test',
        session: TestSession(),
        adapter: fixture,
        delay: (_) async {});
    addTearDown(client.close);
    var model = ProductsController(client, store, 'synthetic-owner:products');
    await model.load();
    fixture.failAfterCommit = true;
    await model.adjust(syntheticProductId, -2, 'Synthetic stock count');
    expect(model.pending, isNotNull);
    final key = fixture.writes.single.headers['Idempotency-Key'];
    model.dispose();
    await storage.close();
    await storage.initialize();
    fixture.offline = true;
    model = ProductsController(client, store, 'synthetic-owner:products');
    await model.load();
    expect(model.cached, isTrue);
    expect(model.products.single.stockQty, 12);
    expect(model.pending, isNotNull);
    expect(await store.read('different-owner:products'), isEmpty);
    final bytes =
        await File('${directory.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(bytes).contains('Synthetic Cow Milk'), isFalse);
    await tester.pumpWidget(productApp(model, scale: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('Showing your saved catalog'), findsOneWidget);
    fixture.offline = false;
    await tester.ensureVisible(find.text('Retry saved request'));
    await tester.tap(find.text('Retry saved request'));
    await tester.pumpAndSettle();
    expect(model.pending, isNull);
    expect(model.products.single.stockQty, 10);
    expect(fixture.writes.last.headers['Idempotency-Key'], key);
    expect(fixture.entries.single['stockQty'], 10);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
