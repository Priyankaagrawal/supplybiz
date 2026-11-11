import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/notifications/notifications_controller.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';

import '../test/features/notifications/notification_fixture.dart';
import '../test/features/notifications/notifications_test.dart'
    show notificationApp;
import '../test/features/onboarding/onboarding_test.dart' show TestSession;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-033 Android inbox, 200% permission denial and encrypted consent (simulated HTTP/FCM)',
      (tester) async {
    final root = await getApplicationSupportDirectory();
    final directory =
        await Directory('${root.path}/notifications-test').create();
    const secrets = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 'notifications_test'));
    final storage = AppStorage(
        secrets: SecureStore(backend: secrets),
        directory: () async => directory);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        fixture = NotificationFixture(),
        push = FakePushGateway();
    final client = NetworkClient(
        baseUrl: 'https://api.example.test',
        session: TestSession(),
        adapter: fixture,
        delay: (_) async {});
    final model = NotificationsController(
        NotificationsApi(client.dio), notificationOwner);
    addTearDown(client.close);
    addTearDown(model.dispose);
    addTearDown(push.close);
    await model.load('CUSTOMER');
    await tester.pumpWidget(notificationApp(model, push, NotificationSession(),
        scale: 2, store: store));
    await tester.pumpAndSettle();
    expect(find.text('Synthetic order update'), findsOneWidget);
    expect(push.prompts, 0);
    await tester.scrollUntilVisible(find.text('Enable push alerts'), 350);
    await tester.ensureVisible(find.text('Enable push alerts'));
    await tester.tap(find.text('Enable push alerts'));
    await tester.pumpAndSettle();
    expect(push.prompts, 0);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(push.prompts, 1);
    expect(find.textContaining('Alerts are blocked.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    const owner = 'http://10.0.2.2:3000/api/v1:$notificationOwner:push-consent';
    expect((await store.read(owner))['enabled'], 'true');
    expect(await store.read('other-account:push-consent'), isEmpty);
    await storage.close();
    await storage.initialize();
    expect((await store.read(owner))['enabled'], 'true');
    final bytes =
        await File('${directory.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(bytes).contains('push-consent'), isFalse);
  });
}
