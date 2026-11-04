import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supplybiz_mobile/app.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/auth/auth_repository.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import '../test/features/auth/auth_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-016 Android auth, role switch and native logout wipe (simulated API)',
      (tester) async {
    final root = await getApplicationSupportDirectory();
    final directory = await Directory('${root.path}/auth-test').create();
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'supplybiz.auth.test'),
        iOptions: IOSOptions(accountName: 'supplybiz.auth.test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend),
        directory: () async => directory);
    await storage.wipeOnLogout();
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final api = AuthFixture();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authConfigProvider.overrideWithValue(testAuthConfig),
          authStorageProvider.overrideWithValue(DeviceAuthStorage(storage)),
          authAdapterProvider.overrideWithValue(api)
        ],
        child: const SupplyBizApp(
            environment: AppEnvironment.dev, enableAuth: true)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '9000000000');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    Future<void> tap(String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    await tap('Continue with WhatsApp');
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pumpAndSettle();
    expect(find.text('Choose your role'), findsOneWidget);
    await tap('I want to buy');
    expect(await storage.readRefreshToken(), isNotNull);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tap('I sell / supply');
    expect(find.text('Set up your business'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tap('I want to buy');
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tap('Logout from all devices');
    expect(find.text('Sign in'), findsOneWidget);
    expect(await storage.readRefreshToken(), isNull);
    expect(await File('${directory.path}/supplybiz.sqlite').exists(), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
