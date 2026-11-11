import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/customer_device.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/customers/customers_controller.dart';
import 'package:supplybiz_mobile/features/customers/customers_page.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';

import '../test/features/onboarding/onboarding_test.dart' show TestSession;
import '../test/features/customers/customer_fixture.dart';
import '../test/features/customers/customers_test.dart' show customerApp;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-029 Android encrypted customer retry/restart and 200% detail (simulated HTTP)',
      (tester) async {
    final root = await getApplicationSupportDirectory();
    final directory = await Directory('${root.path}/customers-test').create();
    const secrets = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'customers_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: secrets),
        directory: () async => directory);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        fixture = CustomerFixture();
    final client = NetworkClient(
        baseUrl: 'https://api.example.test',
        session: TestSession(),
        adapter: fixture,
        delay: (_) async {});
    addTearDown(client.close);
    var model = CustomersController(client, store, 'synthetic-owner:customers');
    await model.load();
    fixture.failAfterCommit = true;
    await model.save({'status': 'INACTIVE'}, id: syntheticCustomerId);
    expect(model.pending, isNotNull);
    final key = fixture.writes.single.headers['Idempotency-Key'];
    model.dispose();
    await storage.close();
    await storage.initialize();
    fixture.offline = true;
    model = CustomersController(client, store, 'synthetic-owner:customers');
    await model.load();
    expect(model.cached, isTrue);
    expect(model.canEdit, isFalse);
    expect(model.pending, isNotNull);
    expect(await store.read('different-owner:customers'), isEmpty);
    final bytes =
        await File('${directory.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(bytes).contains('Synthetic Customer'), isFalse);
    await tester.pumpWidget(customerApp(model,
        child: const CustomerDetailPage(id: syntheticCustomerId), scale: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('showing saved customers'), findsOneWidget);
    fixture.offline = false;
    await tester.ensureVisible(find.text('Retry saved request'));
    await tester.tap(find.text('Retry saved request'));
    await tester.pumpAndSettle();
    expect(model.pending, isNull);
    expect(model.find(syntheticCustomerId)!.status.value, 'INACTIVE');
    expect(fixture.commits, 1);
    expect(fixture.writes.last.headers['Idempotency-Key'], key);
    // Exercise the actual native channel without opening/placing a phone call.
    expect(
        await customerDeviceChannel
            .invokeMethod<bool>('dial', {'mobile': 'invalid'}),
        isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
