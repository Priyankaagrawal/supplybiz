import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/addresses/addresses_controller.dart';
import '../test/features/onboarding/onboarding_test.dart' show TestSession;
import '../test/features/addresses/address_fixture.dart';
import '../test/features/addresses/addresses_test.dart' show addressApp, reveal;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'TC-290 Android encrypted address retry survives restart and renders at 200%',
      (tester) async {
    final directory =
        await Directory.systemTemp.createTemp('supplybiz-address-test');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'addresses_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend),
        directory: () async => directory);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await storage.initialize();
    final drafts = EncryptedOnboardingDrafts(storage: storage),
        fixture = AddressFixture();
    final client = NetworkClient(
        baseUrl: 'https://api.example.test',
        session: TestSession(),
        adapter: fixture,
        delay: (_) async {});
    addTearDown(client.close);
    var model = AddressesController(client, drafts, 'synthetic:addresses');
    await model.load();
    fixture.loseResponse = true;
    await model.save(AddressInput.fromJson(addressJson()..remove('id')));
    expect(model.pending, isNotNull);
    final key = fixture.writes.single.headers['Idempotency-Key'];
    model.dispose();
    await storage.close();
    await storage.initialize();
    model = AddressesController(client, drafts, 'synthetic:addresses');
    await model.load();
    expect(model.pending, isNotNull);
    expect(fixture.writes, hasLength(1));
    expect(await drafts.read('other:addresses'), isEmpty);
    final bytes =
        await File('${directory.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(bytes).contains('Synthetic flat'), isFalse);
    await tester.pumpWidget(addressApp(model, scale: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry saved request'));
    await settleAddress(tester, model);
    expect(model.pending, isNull);
    expect(model.addresses, hasLength(1));
    expect(model.addresses.single.isDefault, isTrue);
    expect(fixture.writes.last.headers['Idempotency-Key'], key);
    expect(await drafts.read('synthetic:addresses'), isEmpty);
    await reveal(tester, find.text('Delete address'));
    await tester.tap(find.text('Delete address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await settleAddress(tester, model);
    expect(model.addresses, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

Future<void> settleAddress(WidgetTester tester, AddressesController model) async {
  // pumpAndSettle can return between a native DB write and the next scheduled frame.
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!model.busy) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Address operation did not complete');
}
