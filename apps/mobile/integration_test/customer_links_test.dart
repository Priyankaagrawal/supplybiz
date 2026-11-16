// T-053 / TC-064: native Android SQLCipher/restart/200%; HTTP is simulated.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/customers/customer_links_controller.dart';
import 'package:supplybiz_mobile/features/customers/customer_links_prompt.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import '../test/features/customers/customer_links_test.dart'
    show LinkFixture, linkApp, linkId, settleLinks;
import '../test/features/notifications/notification_fixture.dart'
    show NotificationSession;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-053 TC-064 Android consent, encrypted lost-response restart/replay, logout and 200%',
      (tester) async {
    Future<void> until(bool Function() ready) async {
      for (var i = 0; i < 100 && !ready(); i++) {
        await settleLinks(tester);
      }
      expect(ready(), isTrue,
          reason: 'Native link consent/cache did not finish.');
    }

    final dir =
        await Directory.systemTemp.createTemp('supplybiz-customer-links-test');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 't053-customer-links'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        f = LinkFixture(),
        session = NotificationSession();
    await tester.pumpWidget(linkApp(f, store, session, scale: 2));
    await until(() => find.text('Synthetic vendor').evaluate().isNotEmpty);
    expect(f.keys, isEmpty);
    await tester.ensureVisible(find.text('Decline link'));
    await tester.tap(find.text('Decline link'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(f.keys, isEmpty);
    f.loseResponse = true;
    await tester.ensureVisible(find.text('Link account'));
    await tester.tap(find.text('Link account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await settleLinks(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(CustomerLinksPrompt)));
    await until(() =>
        !container.read(customerLinksProvider).busy &&
        container.read(customerLinksProvider).pending != null);
    expect(container.read(customerLinksProvider).completed, isNull);
    final key = f.keys.single;
    final owner = container.read(customerLinksProvider).owner;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final bytes = await File('${dir.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(bytes).contains(key), isFalse);
    await tester.pumpWidget(linkApp(f, store, NotificationSession(), scale: 2));
    await until(() => find
        .textContaining('Retry the saved acceptance')
        .evaluate()
        .isNotEmpty);
    await tester.ensureVisible(find.text('Retry saved request'));
    await tester.tap(find.text('Retry saved request'));
    await until(() => find.text('Account linked.').evaluate().isNotEmpty);
    expect(f.keys, [key, key]);
    expect(f.decisions, {linkId: 'ACCEPTED'});
    expect(
        find.text('No vendor accounts waiting to be linked.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await storage.wipeOnLogout();
    await storage.initialize();
    expect(await store.read(owner), isEmpty);
    // The namespace contains no surviving pending consent after a logout wipe.
    final nextSession = NotificationSession()..role = 'VENDOR';
    await tester.pumpWidget(linkApp(f, store, nextSession));
    await settleLinks(tester);
    expect(find.byType(CustomerLinksPrompt), findsOneWidget);
    expect(find.text('Link vendor accounts'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
