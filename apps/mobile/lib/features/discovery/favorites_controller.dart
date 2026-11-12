// T-044: one account-wide mutation owner, durable exact retry and 24-hour replay guard.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/app_failure.dart';
import '../auth/session_controller.dart';
import '../home/home_controller.dart';
import '../onboarding/onboarding_controller.dart';

final favoritesProvider =
    ChangeNotifierProvider.autoDispose<FavoritesController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final scope = ref.watch(homeProvider.select((m) => (m.owner, m.location)));
  final client = homeClient(ref);
  ref.onDispose(client.close);
  final model = FavoritesController(DiscoveryApi(client.dio),
      ref.read(onboardingDraftsProvider), '${scope.$1}:favorites', scope.$2);
  if (identity.$1 != null && identity.$2 == 'CUSTOMER') {
    Future.microtask(model.load);
  }
  return model;
});

class FavoritesController extends ChangeNotifier {
  FavoritesController(this.api, this.store, this.owner, this.location);
  final DiscoveryApi api;
  final OnboardingDrafts store;
  final String owner;
  final HomeLocation? location;
  Map<String, dynamic>? pending;
  AppFailure? failure;
  bool busy = false, ready = false, _disposed = false;
  int revision = 0;
  bool get canEdit =>
      ready && !busy && pending == null && location != null && !_disposed;
  bool get expired {
    final at = pending?['created'] as int?;
    if (at == null) return pending != null;
    final age = DateTime.now().millisecondsSinceEpoch - at;
    return age < 0 || age >= const Duration(hours: 24).inMilliseconds;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _persist() =>
      store.write(owner, {if (pending != null) 'pending': jsonEncode(pending)});
  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      if (_disposed) return;
      failure = e is DioException
          ? mapDioFailure(e)
          : e is AppFailure
              ? e
              : const UnknownFailure();
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        pending = null;
        try {
          await _persist();
        } catch (_) {
          failure = const UnknownFailure(code: 'CACHE_CLEAR_FAILED');
        }
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> load() => _run(() async {
        final j = await store.read(owner);
        if (_disposed) return;
        pending = j['pending'] == null
            ? null
            : Map<String, dynamic>.from(jsonDecode(j['pending']!) as Map);
        ready = true;
      });
  Future<void> set(String id, bool value) async {
    if (!canEdit) return;
    await _run(() async {
      pending = {
        'id': id,
        'value': value,
        'key': const Uuid().v4(),
        'created': DateTime.now().millisecondsSinceEpoch,
        'lat': location!.latitude,
        'lng': location!.longitude,
        'pincode': location!.pincode
      };
      await _send();
    });
  }

  Future<void> retry() => _run(() async {
        if (expired) {
          throw const BusinessRuleFailure(code: 'FAVORITE_RETRY_EXPIRED');
        }
        await _send();
      });
  Future<void> dismissExpired() => _run(() async {
        if (!expired) return;
        final p = pending!;
        await api.discoveryControllerFavorites(
            lat: p['lat'] as num,
            lng: p['lng'] as num,
            pincode: p['pincode'] as String);
        if (_disposed) return;
        await store.write(owner, {});
        if (!_disposed) {
          pending = null;
          revision++;
        }
      });
  Future<void> _send() async {
    final p = pending;
    if (p == null || _disposed) return;
    await _persist();
    if (_disposed) return;
    try {
      if (p['value'] == true) {
        await api.discoveryControllerAdd(
            id: p['id'] as String,
            lat: p['lat'] as num,
            lng: p['lng'] as num,
            pincode: p['pincode'] as String,
            idempotencyKey: p['key'] as String);
      } else {
        await api.discoveryControllerRemove(
            id: p['id'] as String,
            lat: p['lat'] as num,
            lng: p['lng'] as num,
            pincode: p['pincode'] as String,
            idempotencyKey: p['key'] as String);
      }
    } catch (e) {
      if (_disposed) rethrow;
      final f = e is DioException ? mapDioFailure(e) : e;
      if (f is NotFoundFailure ||
          f is ValidationFailure ||
          f is ConflictFailure ||
          f is BusinessRuleFailure) {
        await store.write(owner, {});
        pending = null;
        revision++;
      }
      rethrow;
    }
    if (_disposed) return;
    await store.write(owner, {});
    if (_disposed) return;
    pending = null;
    revision++;
  }
}
