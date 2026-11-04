import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supplybiz_mobile/app.dart';
import 'package:supplybiz_mobile/core/config/app_config.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import '../test/core/config/app_config_test.dart' show ConfigFixture;
import '../test/features/auth/auth_fixture.dart' show testAuthConfig;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-017 Android native version, persisted cache, offline update block (simulated API)',
      (tester) async {
    final root = await getApplicationSupportDirectory();
    final directory = await Directory('${root.path}/config-test').create();
    final cache = FileConfigCache(directory: () async => directory);
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    expect(await AndroidAppInfo().version(), '0.1.0');
    final api = ConfigFixture()..minimum = '0.2.0';
    Future<void> launch() async {
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authConfigProvider.overrideWithValue(testAuthConfig),
            configCacheProvider.overrideWithValue(cache),
            configAdapterProvider.overrideWithValue(api),
          ],
          child: const SupplyBizApp(
              environment: AppEnvironment.dev, enableConfig: true)));
      await tester.pumpAndSettle();
    }

    await launch();
    expect(find.text('Update Supply Biz to continue.'), findsOneWidget);
    // Wait for the atomic cache rename, then reconstruct the provider/app.
    await tester.runAsync(() async {
      for (var i = 0;
          i < 20 &&
              !await File('${directory.path}/mobile-config.json').exists();
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect((await cache.read(testAuthConfig.baseUrl))!.minVersionAndroid,
          '0.2.0');
      expect(await cache.read('https://different.example.test/api/v1'), isNull);
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    api.offline = true;
    await launch();
    expect(find.text('Update Supply Biz to continue.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Update Supply Biz to continue.'), findsOneWidget);
    api.offline = false;
    api.minimum = '0.1.0';
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
