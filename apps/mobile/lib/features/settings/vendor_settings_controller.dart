// T-106 / S-V-20/31/33. Encrypted scoped reads and explicit frozen write retries.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/app_config.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../auth/session_controller.dart';
import '../onboarding/onboarding_controller.dart';

final vendorSettingsProvider =
    ChangeNotifierProvider.autoDispose<VendorSettingsController>((ref) {
  final identity = ref.watch(sessionProvider
          .select((s) => (s.user?.id, s.user?.activeRole?.value))),
      config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  return VendorSettingsController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:${identity.$2}:vendor-settings');
});
int? settingsPaise(String text) {
  if (!RegExp(r'^\d{1,8}(?:\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.'),
      amount = BigInt.parse(parts[0]) * BigInt.from(100) +
          BigInt.parse((parts.length == 1 ? '' : parts[1]).padRight(2, '0'));
  return amount <= BigInt.from(2147483647) ? amount.toInt() : null;
}

class VendorSettingsController extends ChangeNotifier {
  VendorSettingsController(NetworkClient client, this.store, this.owner)
      : api = VendorOnboardingApi(client.dio);
  final VendorOnboardingApi api;
  final OnboardingDrafts store;
  final String owner;
  VendorProfileResponse? profile;
  AppFailure? failure;
  bool busy = false,
      stale = true,
      cacheUnavailable = false,
      terminal = false,
      _disposed = false,
      _restored = false,
      _storageReady = false;
  Map<String, String> _saved = {};
  bool get pending => _saved.containsKey('key');
  String? get pendingKind => _saved['kind'];
  String? get pendingKey => _saved['key'];
  Map<String, dynamic>? get pendingPayload => _saved['payload'] == null
      ? null
      : Map<String, dynamic>.from(jsonDecode(_saved['payload']!) as Map);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() async {
    if (!_storageReady) throw StateError('Settings storage unavailable');
    if (!_disposed) await store.write(owner, Map.of(_saved));
  }

  AppFailure _error(Object e) => e is DioException
      ? mapDioFailure(e)
      : e is AppFailure
          ? e
          : const UnknownFailure();
  Future<void> _fail(Object e) async {
    if (_disposed) return;
    failure = _error(e);
    terminal =
        e is DioException && [400, 409, 422].contains(e.response?.statusCode);
    if (failure is UnauthorizedFailure ||
        failure is ForbiddenFailure ||
        failure is NotFoundFailure) {
      profile = null;
      stale = true;
      _saved = {};
      try {
        await _persist();
      } catch (_) {
        cacheUnavailable = true;
      }
    }
  }

  Future<void> load() async {
    if (_disposed || busy) return;
    busy = true;
    failure = null;
    stale = true;
    _notify();
    try {
      if (!_restored) {
        try {
          _saved = await store.read(owner);
          if (_disposed) return;
          _restored = true;
          _storageReady = true;
          if (_saved['profile'] != null) {
            profile = VendorProfileResponse.fromJson(Map<String, dynamic>.from(
                jsonDecode(_saved['profile']!) as Map));
          }
        } catch (_) {
          cacheUnavailable = true;
          _storageReady = false;
        }
      }
      final value = (await api.vendorsControllerSettings()).data!;
      if (_disposed) return;
      profile = value;
      stale = false;
      _saved['profile'] = jsonEncode(value.toJson());
      try {
        await _persist();
      } catch (_) {
        cacheUnavailable = true;
      }
    } catch (e) {
      await _fail(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> save(String kind, Map<String, dynamic> value) async {
    if (_disposed || busy || stale || profile == null) return;
    busy = true;
    failure = null;
    terminal = false;
    _notify();
    try {
      if (!pending) {
        _saved.addAll({
          'key': const Uuid().v4(),
          'kind': kind,
          'payload': jsonEncode(value)
        });
      }
      await _persist();
      if (_disposed) return;
      final body =
              Map<String, dynamic>.from(jsonDecode(_saved['payload']!) as Map),
          key = _saved['key']!;
      final VendorProfileResponse result;
      if (pendingKind == 'business') {
        result = (await api.vendorsControllerEditBusiness(
                idempotencyKey: key,
                vendorBusinessEditDto: VendorBusinessEditDto.fromJson(body)))
            .data!;
      } else {
        result = (await api.vendorsControllerDelivery(
                idempotencyKey: key,
                vendorDeliveryDto: VendorDeliveryDto.fromJson(body)))
            .data!;
      }
      if (_disposed) return;
      profile = result;
      stale = false;
      final before = Map<String, String>.of(_saved);
      _saved['profile'] = jsonEncode(result.toJson());
      for (final k in ['key', 'kind', 'payload']) {
        _saved.remove(k);
      }
      try {
        await _persist();
      } catch (_) {
        _saved = before;
        cacheUnavailable = true;
        throw const UnknownFailure();
      }
    } catch (e) {
      await _fail(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> retry() async {
    if (pending) await save(pendingKind!, {});
  }

  Future<void> reviewConflict() async {
    if (!terminal || busy) return;
    final before = Map<String, String>.of(_saved);
    for (final k in ['key', 'kind', 'payload']) {
      _saved.remove(k);
    }
    try {
      await _persist();
      terminal = false;
      await load();
    } catch (_) {
      _saved = before;
      cacheUnavailable = true;
      _notify();
    }
  }
}
