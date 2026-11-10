import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_pages.dart';
import 'package:supplybiz_mobile/core/storage/onboarding_device.dart';
import '../test/features/onboarding/onboarding_test.dart'
    show OnboardingFixture, TestSession;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-024 Android encrypted v1 migration, restart drafts, screen security and KYC UI (simulated API)',
      (tester) async {
    final root = await getApplicationSupportDirectory();
    final directory = await Directory('${root.path}/onboarding-test').create();
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'onboarding_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend),
        directory: () async => directory);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await storage.initialize();
    // Reconstruct the real v1 empty local schema, then open through the v2 migration.
    await storage.database.customStatement('DROP TABLE onboarding_drafts');
    await storage.database.customStatement('PRAGMA user_version=1');
    await storage.close();
    await storage.initialize();
    final drafts = EncryptedOnboardingDrafts(storage: storage);
    final api = OnboardingFixture()..step = 3;
    final client = NetworkClient(
        baseUrl: 'https://api.example.test',
        session: TestSession(),
        adapter: api);
    addTearDown(client.close);
    var model = OnboardingController(client, drafts, 'synthetic-owner');
    await model.load();
    model.edit('holderName', 'Synthetic unfinished holder');
    await model.flush();
    model.dispose();
    await storage.close();
    await storage.initialize();
    model = OnboardingController(client, drafts, 'synthetic-owner');
    await model.load();
    expect(model.values['holderName'], 'Synthetic unfinished holder');
    expect(await drafts.read('another-owner'), isEmpty);
    final db = await File('${directory.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(db).contains('Synthetic unfinished holder'),
        false);
    await tester.pumpWidget(ProviderScope(
        overrides: [onboardingProvider.overrideWith((ref) => model)],
        child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingPage())));
    await tester.pumpAndSettle();
    expect(await onboardingChannel.invokeMethod<bool>('isSecure'), true);
    expect(find.text('Step 3 of 4'), findsOneWidget);
    expect(find.text('Synthetic unfinished holder'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(await onboardingChannel.invokeMethod<bool>('isSecure'), false);
  });
}
