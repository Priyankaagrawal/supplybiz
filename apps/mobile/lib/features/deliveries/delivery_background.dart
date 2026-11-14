// T-050 / MOBILE_STRATEGY §6. Android only; no UI, tokens or PII in job input.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;
import 'package:device_coordination/device_coordination.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/storage/app_storage.dart';
import '../../core/config/app_config.dart';
import '../../core/network/network_client.dart';
import '../auth/auth_repository.dart';
import '../auth/session_controller.dart';
import '../onboarding/onboarding_controller.dart';
import 'deliveries_controller.dart';

const deliverySyncTask = 'in.supplybiz.delivery-sync';
Future<void>? _initialization;

Future<void> scheduleDeliverySync() async {
  if (!Platform.isAndroid) return;
  await (_initialization ??=
      Workmanager().initialize(deliveryCallbackDispatcher));
  await Workmanager().registerOneOffTask(deliverySyncTask, deliverySyncTask,
      existingWorkPolicy: ExistingWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30));
}

@pragma('vm:entry-point')
void deliveryCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != deliverySyncTask) return true;
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return runDeliveryWorker();
  });
}

/// Dependencies can be injected for native checks without any production test
/// flags or alternative callback routing. Every snapshot/session access is under
/// the same native lock as foreground delivery operations and session rotation.
Future<bool> runDeliveryWorker(
    {AppStorage? storage, ProviderContainer? container}) async {
  final device = storage ?? AppStorage.instance;
  ProviderContainer? ownedProviders;
  try {
    return await DeviceCoordination.exclusive(() async {
      try {
        await device.initialize();
        final rows = await device.database
            .customSelect(
                "SELECT payload FROM onboarding_drafts WHERE substr(owner, -11) = ':deliveries'")
            .get();
        final hasWork = rows.any((row) {
          final saved = jsonDecode(row.read<String>('payload')) as Map;
          final snapshot = jsonDecode(saved['snapshot'] as String) as Map;
          return (snapshot['queue'] as List)
              .any((a) => a['state'] == 'PENDING' || a['state'] == 'SENDING');
        });
        if (!hasWork || await device.readRefreshToken() == null) return true;
        final version = await DeviceCoordination.appVersion();
        final providers = container ??
            (ownedProviders = ProviderContainer(overrides: [
              authStorageProvider.overrideWithValue(DeviceAuthStorage(device)),
              configProvider.overrideWith(() => _WorkerConfig(version)),
            ]));
        await providers.read(sessionProvider.notifier).restore();
        final session = providers.read(sessionProvider);
        // A transient refresh failure requests Android retry; a revoked session
        // is wiped by SessionController, and must never re-send its old queue.
        if (session.user == null) {
          return session.failure == null ||
              providers.read(configProvider).serverBlocked;
        }
        if (session.user!.activeRole?.value != 'VENDOR') return true;
        final client = NetworkClient(
          baseUrl: Uri.parse(providers.read(authConfigProvider).baseUrl)
              .replace(path: '')
              .toString(),
          session: providers.read(sessionProvider.notifier),
          adapter: providers.read(authAdapterProvider),
          appVersion: () => providers.read(configProvider).version,
          onUpgradeRequired: () =>
              providers.read(configProvider.notifier).requireUpdate(),
        );
        final model = DeliveriesController(
            client.dio,
            EncryptedOnboardingDrafts(storage: device),
            '${providers.read(authConfigProvider).baseUrl}:${session.user!.id}:deliveries',
            coordinated: true);
        try {
          await model.flush();
          return model.failure == null &&
              !model.queue.any((a) => !a.rejected && !a.retryable);
        } finally {
          model.dispose();
          client.close();
        }
      } finally {
        // Do not leave an engine's SQLCipher handle open across a logout wipe.
        await device.close();
      }
    });
  } catch (_) {
    // WorkManager retries with bounded per-action attempts. No raw error, token,
    // payload, customer information or provider response is logged.
    return false;
  } finally {
    ownedProviders?.dispose();
  }
}

// Headless engines have no Activity channel. The native package version still
// supplies the same Android min-version guard headers as the foreground app.
class _WorkerConfig extends ConfigController {
  _WorkerConfig(this.version);
  final String version;
  @override
  ConfigState build() => ConfigState(version: version, loading: false);
  @override
  Future<void> requireUpdate() async {
    state = ConfigState(version: version, loading: false, serverBlocked: true);
  }
}
