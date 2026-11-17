// T-076: actual Android SQLCipher/recreation/logout/200% UI. HTTP is simulated.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/subscriptions/vendor_subscriptions_pages.dart';
import '../test/features/subscriptions/subscription_fixture.dart';
import '../test/features/subscriptions/vendor_subscriptions_test.dart'
    show subscriptionModel, subscriptionInput, subscriptionApp;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-076 native encrypted saved mutation, recreation/replay, plan controls, logout and 200%',
      (tester) async {
    final dir =
        await Directory.systemTemp.createTemp('supplybiz-vendor-subscriptions');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 't076-subscriptions'));
    final storage = AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    await storage.initialize();
    final store = EncryptedOnboardingDrafts(storage: storage),
        f = SubscriptionFixture();
    final first = subscriptionModel(f, store);
    await first.load();
    f.loseResponse = true;
    await first.submit('CREATE', subscriptionInput());
    expect(first.pending, isNotNull);
    final key = first.pending!['key'] as String, owner = first.owner;
    first.dispose();
    first.client.close();
    final bytes = await File('${dir.path}/supplybiz.sqlite').readAsBytes();
    expect(String.fromCharCodes(bytes).contains(key), isFalse);
    final restored = subscriptionModel(f, store);
    await restored.load();
    expect(restored.pending!['key'], key);
    expect(restored.canWrite, isFalse);
    expect(f.writes, hasLength(1));
    await restored.retry();
    expect(restored.pending, isNull);
    expect(f.commits, 1);
    expect(f.writes.last.headers['Idempotency-Key'], key);
    f.controls['canEditSubscriptions'] = false;
    await restored.load();
    await tester.pumpWidget(subscriptionApp(restored,
        child: const VendorSubscriptionSettingsPage(), scale: 2));
    await tester.pumpAndSettle();
    final auto = find.widgetWithText(
        SwitchListTile, 'Automatically accept subscription orders');
    await tester.scrollUntilVisible(auto, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(auto);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(auto).onChanged, isNull);
    final pause =
        find.widgetWithText(SwitchListTile, 'Pause all subscriptions');
    await tester.scrollUntilVisible(pause, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(pause);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(pause).onChanged, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    restored.client.close();
    await storage.wipeOnLogout();
    await storage.initialize();
    expect(await store.read(owner), isEmpty);
    final next =
        subscriptionModel(f, store, owner: 'other:vendor-subscriptions');
    f.offline = true;
    await next.load();
    expect(next.rows, isEmpty);
    expect(next.pending, isNull);
    next.dispose();
    next.client.close();
  });
}
