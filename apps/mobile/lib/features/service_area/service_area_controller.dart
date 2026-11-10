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

final serviceAreaProvider =
    ChangeNotifierProvider.autoDispose<ServiceAreaController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final config = ref.read(authConfigProvider);
  final client = NetworkClient(
    baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
    session: ref.read(sessionProvider.notifier),
    adapter: ref.read(authAdapterProvider),
    appVersion: () => ref.read(configProvider).version,
  );
  final controller = ServiceAreaController(
      client,
      ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:service-area');
  ref.onDispose(client.close);
  if (identity.$1 != null && identity.$2 == 'VENDOR') {
    Future.microtask(controller.load);
  }
  return controller;
});

/// Server remains authoritative. Only pending mutation keys/payloads are stored,
/// in the existing encrypted, account-scoped draft store wiped on logout.
class ServiceAreaController extends ChangeNotifier {
  ServiceAreaController(NetworkClient client, this.drafts, this.owner)
      : api = VendorOnboardingApi(client.dio);
  final VendorOnboardingApi api;
  final OnboardingDrafts drafts;
  final String owner;
  VendorProfileResponse? profile;
  AppFailure? failure;
  bool busy = false, saved = false, _disposed = false;
  final _pending = <String, String>{};

  Map<String, String> get pendingFields {
    final result = <String, String>{};
    final location = _pending['locationPayload'];
    if (location != null) {
      final payload = jsonDecode(location) as Map<String, dynamic>;
      for (final name in [
        'city',
        'state',
        'pincode',
        'latitude',
        'longitude'
      ]) {
        result[name] = '${payload[name] ?? ''}';
      }
      result['address'] = '${payload['addressLine'] ?? ''}';
    }
    final coverage = _pending['coveragePayload'];
    if (coverage != null) {
      final payload = jsonDecode(coverage) as Map<String, dynamic>;
      result['radius'] = '${payload['serviceRadiusKm'] ?? ''}';
      result['pincodes'] = (payload['pincodes'] as List<dynamic>).join(', ');
    }
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    saved = false;
    failure = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      failure =
          error is DioException ? mapDioFailure(error) : const UnknownFailure();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> load() => _run(() async {
        final pending = await drafts.read(owner);
        if (_disposed) return;
        _pending.addAll(pending);
        final result = (await api.vendorsControllerServiceArea()).data!;
        if (!_disposed) profile = result;
      });

  Future<String> _key(String action, Map<String, dynamic> payload) async {
    final encoded = jsonEncode(payload);
    if (_pending['${action}Payload'] != encoded) {
      _pending['${action}Payload'] = encoded;
      _pending['${action}Key'] = const Uuid().v4();
    }
    await drafts.write(owner, Map.of(_pending));
    if (_disposed) throw StateError('Disposed');
    return _pending['${action}Key']!;
  }

  Future<void> saveCoverage(int? radius, List<String> pincodes) =>
      _run(() async {
        final payload =
            ServiceAreaDto(serviceRadiusKm: radius, pincodes: pincodes);
        final key = await _key('coverage', payload.toJson());
        final result = (await api.vendorsControllerSaveServiceArea(
                idempotencyKey: key, serviceAreaDto: payload))
            .data!;
        await _accept('coverage', result);
      });

  Future<void> saveLocation(
          {required String address,
          required String city,
          required String state,
          required String pincode,
          required double latitude,
          required double longitude}) =>
      _run(() async {
        final current = profile!;
        final payload = VendorBusinessDto(
            businessName: current.businessName!,
            gstin: current.gstin,
            shopPhotoMediaId: current.shopPhotoMediaId,
            addressLine: address,
            city: city,
            state: state,
            pincode: pincode,
            latitude: latitude,
            longitude: longitude);
        final key = await _key('location', payload.toJson());
        final result = (await api.vendorsControllerBusiness(
                idempotencyKey: key, vendorBusinessDto: payload))
            .data!;
        await _accept('location', result);
      });

  Future<void> _accept(String action, VendorProfileResponse result) async {
    if (_disposed) return;
    profile = result;
    _pending.remove('${action}Payload');
    _pending.remove('${action}Key');
    await drafts.write(owner, Map.of(_pending));
    saved = true;
  }
}

List<String> parsePincodes(String text) =>
    text.trim().isEmpty ? [] : text.trim().split(RegExp(r'[\s,]+'));
bool validCoverage(String radius, String pincodes) {
  final value = int.tryParse(radius.trim());
  final codes = parsePincodes(pincodes);
  return (radius.trim().isEmpty ||
          (value != null && value >= 1 && value <= 20)) &&
      (value != null || codes.isNotEmpty) &&
      codes.every((code) => RegExp(r'^[1-9]\d{5}$').hasMatch(code)) &&
      codes.toSet().length == codes.length;
}
