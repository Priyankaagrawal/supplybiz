import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/device_location.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/service_area/service_area_controller.dart';
import 'package:supplybiz_mobile/features/service_area/service_area_page.dart';

import '../test/features/onboarding/onboarding_test.dart' show TestSession;
import '../test/features/service_area/service_area_test.dart' show AreaApi;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'TC-028 Android encrypted retry recovery and service-area form (simulated API)',
      (tester) async {
    final root = await getApplicationSupportDirectory();
    final directory =
        await Directory('${root.path}/service-area-test').create();
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'service_area_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend),
        directory: () async => directory);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await storage.initialize();
    final drafts = EncryptedOnboardingDrafts(storage: storage);
    final api = AreaApi()..step = 4;
    final client = NetworkClient(
        baseUrl: 'https://api.example.test',
        session: TestSession(),
        adapter: api,
        delay: (_) async {});
    addTearDown(client.close);
    var model =
        ServiceAreaController(client, drafts, 'synthetic-owner:service-area');
    await model.load();
    api.failures = 20;
    await model.saveCoverage(5, ['110001']);
    expect(model.failure, isNotNull);
    final key = api.writes.first.headers['Idempotency-Key'];
    model.dispose();
    await storage.close();
    await storage.initialize();
    model =
        ServiceAreaController(client, drafts, 'synthetic-owner:service-area');
    await model.load();
    expect(model.pendingFields, {'radius': '5', 'pincodes': '110001'});
    expect(await drafts.read('another-owner:service-area'), isEmpty);
    final bytes =
        await File('${directory.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(bytes).contains('110001'), isFalse);
    await tester.pumpWidget(ProviderScope(
        overrides: [serviceAreaProvider.overrideWith((ref) => model)],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: const ServiceAreaPage())));
    await tester.pumpAndSettle();
    api.failures = 0;
    await tester.ensureVisible(find.text('Save coverage'));
    await tester.tap(find.text('Save coverage'));
    await tester.pumpAndSettle();
    expect(find.text('Saved to server.'), findsOneWidget);
    expect(api.writes.last.headers['Idempotency-Key'], key);
    expect(await drafts.read('synthetic-owner:service-area'), isEmpty);
    await model.load();
    expect(model.profile?.settings.serviceRadiusKm, 5);
    expect(model.profile?.settings.pincodes, ['110001']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'TC-028 Android native location request cancellation releases the channel',
      (tester) async {
    const device = DeviceLocation();
    // Accept a fresh fix or a documented platform failure, never an unhandled request.
    // Cancel explicitly so the test does not require a real satellite fix.
    for (var i = 0; i < 2; i++) {
      final request = device
          .current()
          .then<Object>((point) => point, onError: (Object error) => error);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await device.cancel();
      final result = await request.timeout(const Duration(seconds: 3));
      if (result is PlatformException) {
        expect(
            result.code,
            isIn([
              'LOCATION_CANCELLED',
              'LOCATION_UNAVAILABLE',
              'LOCATION_DENIED'
            ]));
      } else {
        expect(result, isA<(double, double)>());
      }
    }
  });
}
