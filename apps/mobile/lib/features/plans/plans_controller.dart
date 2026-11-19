// T-105 / US-120/121. Read-only server assignments, no local entitlement grants.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../auth/session_controller.dart';
import '../onboarding/onboarding_controller.dart';

final plansProvider =
    ChangeNotifierProvider.autoDispose<PlansController>((ref) {
  final identity = ref.watch(sessionProvider
          .select((s) => (s.user?.id, s.user?.activeRole?.value))),
      config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  return PlansController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:${identity.$2}:vendor-plans');
});

class PlansController extends ChangeNotifier {
  PlansController(this.client, this.store, this.owner)
      : api = VendorPlansApi(client.dio);
  final NetworkClient client;
  final OnboardingDrafts store;
  final String owner;
  final VendorPlansApi api;
  CurrentPlanResponse? current;
  List<PlanCatalogRow> catalog = [];
  AppFailure? currentFailure, catalogFailure;
  bool currentStale = true,
      catalogStale = true,
      catalogLoaded = false,
      busy = false,
      cacheUnavailable = false;
  bool _restored = false, _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final saved = await store.read(owner);
      if (_disposed) return;
      if (saved['current'] != null) {
        current = CurrentPlanResponse.fromJson(
            Map<String, dynamic>.from(jsonDecode(saved['current']!) as Map));
      }
      catalog = (jsonDecode(saved['catalog'] ?? '[]') as List)
          .take(4)
          .map((e) =>
              PlanCatalogRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      catalogLoaded = saved.containsKey('catalog');
    } catch (_) {
      current = null;
      catalog = [];
      cacheUnavailable = true;
    }
  }

  Future<void> _save() async {
    if (_disposed) return;
    await store.write(owner, {
      if (current != null) 'current': jsonEncode(current!.toJson()),
      if (catalogLoaded)
        'catalog': jsonEncode(catalog.take(4).map((e) => e.toJson()).toList()),
    });
  }

  bool _denial(AppFailure f) =>
      f is UnauthorizedFailure || f is ForbiddenFailure || f is NotFoundFailure;
  Future<void> _clear() async {
    current = null;
    catalog = [];
    catalogLoaded = false;
    currentStale = true;
    catalogStale = true;
    try {
      await store.write(owner, {});
    } catch (_) {
      cacheUnavailable = true;
    }
  }

  AppFailure _failure(Object e) => e is DioException
      ? mapDioFailure(e)
      : e is AppFailure
          ? e
          : const UnknownFailure();
  Future<void> load() async {
    if (_disposed || busy) return;
    busy = true;
    currentFailure = null;
    catalogFailure = null;
    cacheUnavailable = false;
    notifyListeners();
    try {
      await _restore();
      if (_disposed) return;
      currentStale = true;
      catalogStale = true;
      notifyListeners();
      try {
        final result = (await api.vendorPlansControllerCurrent()).data!;
        if (_disposed) return;
        current = result;
        currentStale = false;
        notifyListeners();
      } catch (e) {
        if (_disposed) return;
        currentFailure = _failure(e);
        if (_denial(currentFailure!)) {
          await _clear();
          return;
        }
      }
      try {
        final result = (await api.vendorPlansControllerCatalog()).data!;
        if (_disposed) return;
        catalog =
            result.items.where((p) => p.status.value == 'ACTIVE').toList();
        catalogLoaded = true;
        catalogStale = false;
      } catch (e) {
        if (_disposed) return;
        catalogFailure = _failure(e);
        if (_denial(catalogFailure!)) {
          await _clear();
          return;
        }
      }
      if (_disposed) return;
      try {
        await _save();
      } catch (_) {
        if (!_disposed) cacheUnavailable = true;
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }
}
