// T-031 / US-020: read-only, bounded encrypted account/role/environment cache.
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
import '../notifications/order_notices.dart';
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionDate, subscriptionParseDate;

final dashboardProvider =
    ChangeNotifierProvider.autoDispose<DashboardController>((ref) {
  final identity = ref.watch(sessionProvider
          .select((s) => (s.user?.id, s.user?.activeRole?.value))),
      config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  final model = DashboardController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:${identity.$2}:vendor-dashboard');
  listenForOrderNotices(ref, identity.$1, 'VENDOR', model.load);
  return model;
});

class DashboardController extends ChangeNotifier {
  DashboardController(this.client, this.store, this.owner)
      : api = VendorDashboardApi(client.dio),
        plans = VendorPlansApi(client.dio),
        media = MediaApi(client.dio);
  final NetworkClient client;
  final OnboardingDrafts store;
  final String owner;
  final VendorDashboardApi api;
  final VendorPlansApi plans;
  final MediaApi media;
  final _cache = <String, VendorDashboard>{};
  VendorDashboard? metrics;
  CurrentPlanResponse? plan;
  Uint8List? photo;
  AppFailure? failure;
  bool busy = false,
      stale = true,
      planUnavailable = false,
      cacheUnavailable = false;
  bool _disposed = false, _restored = false;
  String? requestedDate, _lastBusinessDate, _photoId;
  bool get todayMode => requestedDate == null;
  String? get selectedDate =>
      requestedDate ??
      (metrics == null ? _lastBusinessDate : subscriptionDate(metrics!.date));
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _save() => store.write(owner, {
        'metrics': jsonEncode(_cache.values.map((m) => m.toJson()).toList()),
        if (_lastBusinessDate != null) 'businessDate': _lastBusinessDate!,
        if (plan != null) 'plan': jsonEncode(plan!.toJson()),
      });
  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final saved = await store.read(owner);
      if (_disposed) return;
      for (final value
          in (jsonDecode(saved['metrics'] ?? '[]') as List).take(14)) {
        final m =
            VendorDashboard.fromJson(Map<String, dynamic>.from(value as Map));
        _cache[subscriptionDate(m.date)] = m;
      }
      _lastBusinessDate = saved['businessDate'];
      if (saved['plan'] != null) {
        plan = CurrentPlanResponse.fromJson(
            Map<String, dynamic>.from(jsonDecode(saved['plan']!) as Map));
      }
    } catch (_) {
      _cache.clear();
      plan = null;
      cacheUnavailable = true;
    }
  }

  Future<void> _deny() async {
    metrics = null;
    plan = null;
    photo = null;
    _photoId = null;
    _cache.clear();
    _lastBusinessDate = null;
    try {
      await store.write(owner, {});
    } catch (_) {
      cacheUnavailable = true;
    }
  }

  Future<void> load({String? date, bool today = false}) async {
    if (_disposed || busy) return;
    if (date != null && subscriptionParseDate(date) == null) return;
    busy = true;
    failure = null;
    cacheUnavailable = false;
    notifyListeners();
    try {
      await _restore();
      if (_disposed) return;
      if (today) {
        requestedDate = null;
      } else if (date != null) {
        requestedDate = date;
      }
      metrics = _cache[requestedDate ?? _lastBusinessDate];
      stale = true;
      photo = null;
      _photoId = null;
      notifyListeners();
      final fresh =
          (await api.vendorDashboardControllerGet(date: requestedDate)).data!;
      if (_disposed) return;
      metrics = fresh;
      _lastBusinessDate = subscriptionDate(fresh.businessDate);
      _cache.remove(subscriptionDate(fresh.date));
      _cache[subscriptionDate(fresh.date)] = fresh;
      while (_cache.length > 14) {
        _cache.remove(_cache.keys.first);
      }
      stale = false;
      plan = null;
      planUnavailable = false;
      notifyListeners();
      try {
        final current = (await plans.vendorPlansControllerCurrent()).data;
        if (_disposed) return;
        plan = current;
      } on DioException catch (e) {
        final f = mapDioFailure(e);
        if (f is UnauthorizedFailure || f is ForbiddenFailure) {
          failure = f;
          await _deny();
          stale = true;
          return;
        }
        planUnavailable = true;
      }
      if (_disposed) return;
      try {
        await _save();
      } catch (_) {
        if (!_disposed) cacheUnavailable = true;
      }
      final photoId = fresh.shopPhotoMediaId;
      if (_disposed || photoId == null) return;
      try {
        final bytes = (await media.mediaControllerContent(id: photoId)).data;
        if (!_disposed && metrics?.shopPhotoMediaId == photoId) {
          photo = bytes;
          _photoId = photoId;
        }
      } on DioException {/* Authorized image unavailable; keep a local icon. */}
    } catch (e) {
      if (_disposed) return;
      failure = e is DioException
          ? mapDioFailure(e)
          : e is AppFailure
              ? e
              : const UnknownFailure();
      stale = true;
      if (failure is UnauthorizedFailure ||
          failure is ForbiddenFailure ||
          failure is NotFoundFailure) {
        await _deny();
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  bool get hasPhoto => photo != null && _photoId == metrics?.shopPhotoMediaId;
}
