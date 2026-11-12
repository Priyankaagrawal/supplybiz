import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/home/home_controller.dart';
import '../test/features/home/home_fixture.dart';
import '../test/features/home/home_test.dart'
    show fixtureClient, homeApp, manualLocation;
import '../test/features/addresses/addresses_test.dart' show reveal;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'TC-200–203 Android encrypted location/recent searches survive restart and home renders at 200%',
      (tester) async {
    final dir = await Directory.systemTemp.createTemp('supplybiz-home-test');
    const backend = FlutterSecureStorage(
        aOptions:
            AndroidOptions(resetOnError: false, storageNamespace: 'home_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        fixture = HomeFixture()..addresses = [];
    final client = fixtureClient(fixture);
    addTearDown(client.close);
    var model = HomeController(client, store, 'synthetic:home');
    await model.load();
    expect(model.location, isNull);
    expect(await model.select(manualLocation), isTrue);
    var search = HomeSearchController(DiscoveryApi(client.dio), model.location,
        null, store, 'synthetic:home:searches');
    await search.search('Synthetic query');
    expect(search.items, hasLength(1));
    model.dispose();
    search.dispose();
    await storage.close();
    await storage.initialize();
    model = HomeController(client, store, 'synthetic:home');
    await model.load();
    expect(model.location?.address, manualLocation.address);
    search = HomeSearchController(DiscoveryApi(client.dio), model.location,
        null, store, 'synthetic:home:searches');
    await search.search('');
    expect(search.recent, ['Synthetic query']);
    search.dispose();
    expect(await store.read('other:home'), isEmpty);
    for (final suffix in ['', '-wal']) {
      final file = File('${dir.path}/supplybiz.sqlite$suffix');
      if (await file.exists()) {
        final bytes = String.fromCharCodes(await file.readAsBytes());
        expect(bytes.contains('Synthetic area'), isFalse);
        expect(bytes.contains('Synthetic query'), isFalse);
      }
    }
    await tester.pumpWidget(homeApp(model, fixture, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Accepted'));
    expect(find.text('Synthetic milk × 2'), findsOneWidget);
    fixture.status = 'PREPARING';
    await model.load();
    await tester.pumpAndSettle();
    expect(find.text('Preparing'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await storage.wipeOnLogout();
    await storage.initialize();
    expect(await store.read('synthetic:home'), isEmpty);
    expect(await store.read('synthetic:home:searches'), isEmpty);
  });
}
