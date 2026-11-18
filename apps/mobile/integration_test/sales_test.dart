// T-080 native SQLCipher/recreation/two-worker smoke. HTTP remains simulated.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/auth/auth_repository.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:supplybiz_mobile/features/deliveries/delivery_background.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import '../test/features/auth/auth_fixture.dart'
    show AuthFixture, testAuthConfig;
import '../test/features/sales/sales_fixture.dart';
import '../test/features/sales/sales_test.dart' show salesModel, salesApp;
import '../test/features/products/catalog_fixture.dart' show syntheticProductId;

class NativeSalesAdapter extends AuthFixture {
  NativeSalesAdapter(this.sales) {
    roles.add('VENDOR');
    activeRole = 'VENDOR';
  }
  final SalesFixture sales;
  @override
  Future<ResponseBody> fetch(
      RequestOptions r, Stream<Uint8List>? stream, Future<void>? cancel) {
    if (r.uri.path.contains('/auth/') || r.uri.path.endsWith('/me')) {
      return super.fetch(r, stream, cancel);
    }
    return sales.fetch(r, stream, cancel);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-080 native encrypted offline queue, stale handles, exact replay, shared worker, logout and 200%',
      (tester) async {
    final dir = await Directory.systemTemp.createTemp('supplybiz-sales-native');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 't080-sales-native'));
    AppStorage make() => AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    final a = make(), b = make(), f = SalesFixture();
    final adapter = NativeSalesAdapter(f),
        owner =
            '${testAuthConfig.baseUrl}:11111111-1111-4111-8111-111111111111:sales';
    final ca = ProviderContainer(overrides: [
      authStorageProvider.overrideWithValue(DeviceAuthStorage(a)),
      authAdapterProvider.overrideWithValue(adapter),
      authConfigProvider.overrideWithValue(testAuthConfig)
    ]);
    final cb = ProviderContainer(overrides: [
      authStorageProvider.overrideWithValue(DeviceAuthStorage(b)),
      authAdapterProvider.overrideWithValue(adapter),
      authConfigProvider.overrideWithValue(testAuthConfig)
    ]);
    addTearDown(() async {
      ca.dispose();
      cb.dispose();
      await a.close();
      await b.close();
      await a.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await a.initialize();
    await b.initialize();
    final storeA = EncryptedOnboardingDrafts(storage: a),
        storeB = EncryptedOnboardingDrafts(storage: b);
    final one = salesModel(f, storeA, owner: owner, coordinated: true),
        two = salesModel(f, storeB, owner: owner, coordinated: true);
    await one.load();
    await two.load();
    f.offline = true;
    await one.enqueue('native-sales-first', saleItems(),
        paidPaise: '6010', method: 'CASH');
    await two.enqueue('native-sales-second', saleItems(),
        paidPaise: '6010', method: 'CASH');
    expect(two.queue, hasLength(2));
    expect(two.available(syntheticProductId), 10);
    expect(f.commits, 0);
    final bytes = await File('${dir.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(bytes).contains('native-sales-first'), isFalse);
    one.dispose();
    two.dispose();
    one.dio.close(force: true);
    two.dio.close(force: true);
    await a.close();
    await b.close();
    await a.initialize();
    final restored = salesModel(f, storeA, owner: owner, coordinated: true);
    f.offline = false;
    f.loseResponse = true;
    await restored.flush(retry: true);
    expect(f.commits, 1);
    expect(restored.queue, hasLength(2));
    expect(restored.receipts, isEmpty);
    restored.dispose();
    restored.dio.close(force: true);
    // Allow the persisted connection backoff, then two independent worker runs
    // acquire the native lease and reopen their own encrypted DB handles.
    await Future<void>.delayed(const Duration(seconds: 5));
    await a.writeRefreshToken('synthetic-refresh');
    final results = await Future.wait([
      runDeliveryWorker(storage: a, container: ca),
      runDeliveryWorker(storage: b, container: cb)
    ]).timeout(const Duration(seconds: 45));
    expect(results, everyElement(isTrue));
    expect(f.commits, 2);
    await a.initialize();
    final check = salesModel(f, storeA, owner: owner, coordinated: true);
    await check.flush();
    expect(check.queue, isEmpty);
    expect(check.receipts, hasLength(2));
    expect(check.available(syntheticProductId), 10);
    expect(
        f.writes
            .where((r) => r.headers['Idempotency-Key'] == 'native-sales-first')
            .map((r) => r.data)
            .toSet(),
        hasLength(1));
    await tester.pumpWidget(salesApp(check, scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    check.dio.close(force: true);
    await a.wipeOnLogout();
    await a.initialize();
    expect(await storeA.read(owner), isEmpty);
    expect(adapter.refreshes, greaterThanOrEqualTo(1));
  });
}
