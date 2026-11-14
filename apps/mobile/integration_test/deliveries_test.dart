import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/deliveries/deliveries_controller.dart';
import '../test/features/orders/orders_test.dart' show ordersClient, orderPhone;
import '../test/features/deliveries/deliveries_test.dart'
    show DeliveriesFixture, deliveriesApp;
import '../test/features/addresses/addresses_test.dart' show reveal;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'TC-086/087/088/504 Android encrypted SENDING recovery, FIFO, conflict, 200% and wipe',
      (tester) async {
    final dir =
        await Directory.systemTemp.createTemp('supplybiz-deliveries-test');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'deliveries_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        f = DeliveriesFixture(),
        http = ordersClient(f);
    addTearDown(http.close);
    var m = DeliveriesController(http.dio, store, 'native:deliveries');
    await m.load();
    f.holdResponse = true;
    f.committed = Completer<void>();
    f.release = Completer<void>();
    final sending = m.enqueue(m.rows.single, 'OUT_FOR_DELIVERY');
    await f.committed!.future;
    expect(m.queue.single.state, 'SENDING');
    final key = m.queue.single.key;
    m.dispose();
    await storage.close();
    await storage.initialize();
    f.holdResponse = false;
    f.release!.complete();
    await sending;
    f.offline = true;
    m = DeliveriesController(http.dio, store, 'native:deliveries');
    await m.load();
    expect(m.queue.single.key, key);
    expect(m.status(m.rows.single), 'OUT_FOR_DELIVERY');
    await m.enqueue(m.rows.single, 'DELIVERED', payment: {
      'collected': true,
      'method': 'UPI',
      'amountPaise': '12020',
    });
    expect(m.queue.length, 2);
    f.offline = false;
    m.queue.first.nextAt = null;
    await m.flush();
    expect(m.queue, isEmpty);
    expect(f.commits, 2);
    expect(m.rows.single.status, 'DELIVERED');
    expect(f.sentKeys.where((k) => k == key).length, greaterThan(1));
    // Render the native widget with real SQLCipher state, simulated HTTP.
    await tester.pumpWidget(deliveriesApp(m, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Synthetic order customer'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    // A rejected offline update rolls back its projection in the encrypted store.
    f.rows.first['status'] = 'OUT_FOR_DELIVERY';
    f.rows.first['version'] = (f.rows.first['version'] as int) + 1;
    m = DeliveriesController(http.dio, store, 'native:deliveries');
    await m.load();
    f.offline = true;
    await m.enqueue(m.rows.single, 'DELIVERED', payment: {'collected': false});
    f.offline = false;
    f.conflict = true;
    m.queue.single.nextAt = null;
    await m.flush();
    expect(m.queue.single.rejected, isTrue);
    expect(m.rows, isEmpty);
    expect(f.commits, 2);
    m.dispose();
    final raw = await File('${dir.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(raw).contains(orderPhone), isFalse);
    await storage.wipeOnLogout();
    await storage.initialize();
    expect(await store.read('native:deliveries'), isEmpty);
  });
}
