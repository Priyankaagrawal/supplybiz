// T-050 / TC-504: native lease + SQLCipher + secure-store session coordination.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:device_coordination/device_coordination.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/auth/auth_repository.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/deliveries/deliveries_controller.dart';
import '../test/features/auth/auth_fixture.dart'
    show AuthFixture, testAuthConfig;
import '../test/features/orders/orders_test.dart' show ordersClient;
import '../test/features/deliveries/deliveries_test.dart'
    show DeliveriesFixture;

class SerialRefreshFixture extends AuthFixture {
  String current = 'synthetic-refresh-0';
  final readTokens = <String>[];
  @override
  Future<ResponseBody> fetch(
      RequestOptions r, Stream<Uint8List>? s, Future<void>? c) async {
    if (!r.path.endsWith('/refresh')) return super.fetch(r, s, c);
    final token = body(r)['refreshToken'] as String;
    expect(token, current,
        reason:
            'A second session must read the newly persisted refresh token.');
    readTokens.add(token);
    final response = await super.fetch(r, s, c);
    current = 'synthetic-refresh-$refreshes';
    return response;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'T-050 TC-504 native lease, stale snapshot, refresh wait-cycle and logout fencing',
      (tester) async {
    final dir =
        await Directory.systemTemp.createTemp('supplybiz-coordination-test');
    const backend = FlutterSecureStorage(
        aOptions: AndroidOptions(
            resetOnError: false, storageNamespace: 't050-coordination-test'));
    AppStorage makeStorage() => AppStorage(
        secrets: SecureStore(backend: backend), directory: () async => dir);
    final a = makeStorage(), b = makeStorage(), stale = makeStorage();
    addTearDown(() async {
      await a.close();
      await b.close();
      await stale.close();
      await a.wipeOnLogout();
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    // Native FIFO and reentrance, without depending on UI rebuild timing.
    final entered = Completer<void>(), release = Completer<void>();
    var secondEntered = false;
    final first = DeviceCoordination.exclusive(() async {
      await DeviceCoordination.exclusive(() async {
        expect(DeviceCoordination.isHeld, isTrue);
      });
      entered.complete();
      await release.future;
    });
    await entered.future;
    final second = DeviceCoordination.exclusive(() async {
      secondEntered = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(secondEntered, isFalse);
    release.complete();
    await Future.wait([first, second]);
    expect(secondEntered, isTrue);
    Future<void> Function()? lateCallback;
    var lateEntered = false;
    await DeviceCoordination.exclusive(() async {
      lateCallback = Zone.current
          .bindCallback(() => DeviceCoordination.exclusive(() async {
                lateEntered = true;
              }));
    });
    // An escaped callback may retain its Zone but not ownership of a released lease.
    final occupied = Completer<void>(), unlock = Completer<void>();
    final occupant = DeviceCoordination.exclusive(() async {
      occupied.complete();
      await unlock.future;
    });
    await occupied.future;
    final late = lateCallback!();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(lateEntered, isFalse);
    unlock.complete();
    await Future.wait([occupant, late]);
    expect(lateEntered, isTrue);
    await DeviceCoordination.exclusive(() async {
      await a.initialize();
      await b.initialize();
    });

    // Two independent DB handles/controllers cannot replace a newer queue.
    final fixture = DeliveriesFixture(), http = ordersClient(fixture);
    addTearDown(http.close);
    final one = DeliveriesController(
        http.dio, EncryptedOnboardingDrafts(storage: a), 'native:deliveries',
        coordinated: true);
    final two = DeliveriesController(
        http.dio, EncryptedOnboardingDrafts(storage: b), 'native:deliveries',
        coordinated: true);
    await one.load();
    await two.load();
    fixture.offline = true;
    await one.enqueue(one.rows.single, 'OUT_FOR_DELIVERY');
    final key = one.queue.single.key;
    await two
        .enqueue(two.rows.single, 'DELIVERED', payment: {'collected': false});
    expect(two.queue.length, 2);
    expect(two.queue.first.key, key);
    one.dispose();
    two.dispose();

    final auth = SerialRefreshFixture()
      ..roles.add('VENDOR')
      ..activeRole = 'VENDOR';
    await a.writeRefreshToken(auth.current);
    ProviderContainer providers(AppStorage storage) =>
        ProviderContainer(overrides: [
          authStorageProvider.overrideWithValue(DeviceAuthStorage(storage)),
          authAdapterProvider.overrideWithValue(auth),
          authConfigProvider.overrideWithValue(testAuthConfig),
        ]);
    final ca = providers(a), cb = providers(b);
    addTearDown(ca.dispose);
    addTearDown(cb.dispose);
    final sa = ca.read(sessionProvider.notifier),
        sb = cb.read(sessionProvider.notifier);
    await Future.wait([sa.restore(), sb.restore()])
        .timeout(const Duration(seconds: 15));
    expect(auth.readTokens, ['synthetic-refresh-0', 'synthetic-refresh-1']);

    // A refresh waiting outside the held delivery lease must not deadlock the
    // held request's 401 refresh by sharing that waiting flight.
    final held = Completer<void>(), allowRefresh = Completer<void>();
    final delivery = DeviceCoordination.exclusive(() async {
      held.complete();
      await allowRefresh.future;
      await sa.refresh();
    });
    await held.future;
    final waitingRefresh = sa.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    allowRefresh.complete();
    await Future.wait([delivery, waitingRefresh])
        .timeout(const Duration(seconds: 15));
    expect(auth.refreshes, 4);

    await stale.initialize();

    // Logout waits for the background write+close, then removes the token/key
    // and DB. A late background completion cannot resurrect them.
    auth.refreshGate = Completer<void>();
    final background = DeviceCoordination.exclusive(() async {
      await sb.refresh();
      await b.close();
    });
    while (auth.refreshes < 5) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final logout = sa.clear();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await a.readRefreshToken(), isNotNull);
    auth.refreshGate!.complete();
    await Future.wait([background, logout])
        .timeout(const Duration(seconds: 15));
    expect(await a.readRefreshToken(), isNull);
    expect(await File('${dir.path}/supplybiz.sqlite').exists(), isFalse);
    expect(ca.read(sessionProvider).user, isNull);
    await expectLater(
        EncryptedOnboardingDrafts(storage: stale)
            .write('stale:deliveries', {'snapshot': '{}'}),
        throwsStateError);
    expect(await File('${dir.path}/supplybiz.sqlite').exists(), isFalse);
  });
}
