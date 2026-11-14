// Standalone Android process-kill probe. Built only by the explicit T-050 smoke;
// this entrypoint and its injected synthetic HTTP/storage never enter main_dev.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;
import 'package:device_coordination/device_coordination.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:supplybiz_mobile/core/config/app_config.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';
import 'package:supplybiz_mobile/features/auth/auth_repository.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/deliveries/deliveries_controller.dart';
import 'package:supplybiz_mobile/features/deliveries/delivery_background.dart';

const _base = 'http://10.0.2.2:33175';
const _user = '11111111-1111-4111-8111-111111111111';
AppStorage _storage() => AppStorage(
      secrets: SecureStore(
          backend: const FlutterSecureStorage(
              aOptions: AndroidOptions(
                  resetOnError: false,
                  storageNamespace: 't050-background-probe'))),
      directory: () async => Directory(
          '${(await getApplicationSupportDirectory()).path}/t050-background-probe'),
    );

class _ProbeSession implements NetworkSession {
  @override
  String? get accessToken => 'synthetic-probe-access';
  @override
  Future<void> refresh() async {}
  @override
  Future<void> clear() async {}
}

class _ProbeConfig extends ConfigController {
  _ProbeConfig(this.version);
  final String version;
  @override
  ConfigState build() => ConfigState(version: version, loading: false);
}

@pragma('vm:entry-point')
void probeDispatcher() {
  Workmanager().executeTask((_, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final storage = _storage();
    final providers = ProviderContainer(overrides: [
      authStorageProvider.overrideWithValue(DeviceAuthStorage(storage)),
      authConfigProvider
          .overrideWithValue(const AuthConfig(baseUrl: '$_base/api/v1')),
      configProvider.overrideWith(() => _ProbeConfig('0.1.0')),
    ]);
    try {
      final done =
          await runDeliveryWorker(storage: storage, container: providers);
      final remaining = await DeviceCoordination.exclusive(() async {
        await storage.initialize();
        final saved = await EncryptedOnboardingDrafts(storage: storage)
            .read('$_base/api/v1:$_user:deliveries');
        final snapshot = jsonDecode(saved['snapshot']!) as Map;
        await storage.close();
        return (snapshot['queue'] as List).length;
      });
      await Dio().post('$_base/worker-result', data: {
        'done': done,
        'remaining': remaining,
        'generation': input?['generation']
      });
      return done;
    } catch (e) {
      await Dio().post('$_base/worker-result', data: {
        'done': false,
        'errorType': e.runtimeType.toString(),
        'generation': input?['generation']
      });
      return false;
    } finally {
      providers.dispose();
      await storage.close();
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final generation = DateTime.now().microsecondsSinceEpoch.toString();
  await Workmanager().initialize(probeDispatcher);
  for (final name in ['t050-probe-one', 't050-probe-two']) {
    await Workmanager().cancelByUniqueName(name);
  }
  final storage = _storage();
  if ((await Dio().get('$_base/probe-mode')).data['cleanup'] == true) {
    await DeviceCoordination.exclusive(() async {
      await storage.wipeOnLogout();
      await storage.close();
    });
    await Dio().post('$_base/probe-cleaned');
    runApp(const MaterialApp(home: SizedBox()));
    return;
  }
  await DeviceCoordination.exclusive(() async {
    await Dio().post('$_base/probe-begin', data: {'generation': generation});
    await storage.wipeOnLogout();
    await storage.initialize();
    await storage.writeRefreshToken('synthetic-refresh-0');
    final client = NetworkClient(
        baseUrl: _base, session: _ProbeSession(), appVersion: () => '0.1.0');
    final m = DeliveriesController(
        client.dio,
        EncryptedOnboardingDrafts(storage: storage),
        '$_base/api/v1:$_user:deliveries',
        coordinated: true);
    await m.load();
    await m.enqueue(m.rows.single,
        'OUT_FOR_DELIVERY'); // server commits, response is deliberately lost
    m.queue.single.nextAt =
        DateTime.now().toUtc().add(const Duration(seconds: 10));
    await m.enqueue(m.rows.single, 'DELIVERED', payment: {
      'collected': true,
      'method': 'UPI',
      'amountPaise': '12020',
    });
    if (m.queue.length != 2) {
      throw StateError('Probe did not save its FIFO queue.');
    }
    m.dispose();
    client.close();
    await storage.close();
  });
  for (final name in ['t050-probe-one', 't050-probe-two']) {
    await Workmanager().registerOneOffTask(name, deliverySyncTask,
        initialDelay: const Duration(seconds: 30),
        inputData: {'generation': generation},
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace);
  }
  await Dio().post('$_base/probe-ready', data: {'generation': generation});
  runApp(const MaterialApp(
      home:
          Scaffold(body: Text('Synthetic Android background delivery probe'))));
}
