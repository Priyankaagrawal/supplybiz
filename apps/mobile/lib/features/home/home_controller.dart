// T-043 / FR-200–203: account-scoped home and discovery location.
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

class HomeLocation {
  const HomeLocation(
      {required this.address,
      required this.city,
      required this.pincode,
      required this.latitude,
      required this.longitude});
  final String address, city, pincode;
  final double latitude, longitude;
  bool get valid =>
      address.trim().isNotEmpty &&
      address.length <= 200 &&
      city.trim().isNotEmpty &&
      city.length <= 100 &&
      RegExp(r'^[1-9]\d{5}$').hasMatch(pincode) &&
      latitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.isFinite &&
      longitude.abs() <= 180;
  Map<String, dynamic> toJson() => {
        'address': address,
        'city': city,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude
      };
  factory HomeLocation.fromJson(Map<String, dynamic> j) => HomeLocation(
      address: j['address'] as String,
      city: j['city'] as String,
      pincode: j['pincode'] as String,
      latitude: (j['latitude'] as num).toDouble(),
      longitude: (j['longitude'] as num).toDouble());
  factory HomeLocation.saved(AddressResponse row) => HomeLocation(
      address: row.line2,
      city: row.city,
      pincode: row.pincode,
      latitude: row.latitude.toDouble(),
      longitude: row.longitude.toDouble());
}

NetworkClient homeClient(Ref ref) => NetworkClient(
    baseUrl: Uri.parse(ref.read(authConfigProvider).baseUrl)
        .replace(path: '')
        .toString(),
    session: ref.read(sessionProvider.notifier),
    adapter: ref.read(authAdapterProvider),
    appVersion: () => ref.read(configProvider).version);
final homeProvider = ChangeNotifierProvider.autoDispose<HomeController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final client = homeClient(ref);
  ref.onDispose(client.close);
  final model = HomeController(client, ref.read(onboardingDraftsProvider),
      '${ref.read(authConfigProvider).baseUrl}:${identity.$1}:home-location');
  if (identity.$1 != null && identity.$2 == 'CUSTOMER') {
    Future.microtask(model.load);
  }
  return model;
});

class HomeController extends ChangeNotifier {
  HomeController(NetworkClient client, this.store, this.owner)
      : api = CustomerHomeApi(client.dio),
        addressesApi = CustomerAddressesApi(client.dio);
  final CustomerHomeApi api;
  final CustomerAddressesApi addressesApi;
  final OnboardingDrafts store;
  final String owner;
  CustomerHome? home;
  HomeLocation? location;
  List<AddressResponse> addresses = [];
  AppFailure? failure;
  bool busy = false, stale = false, _disposed = false, _restored = false;
  bool get alive => !_disposed;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      if (_disposed) return;
      failure = error is DioException
          ? mapDioFailure(error)
          : error is AppFailure
              ? error
              : const UnknownFailure();
      stale = true;
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        home = null;
        location = null;
        addresses = [];
        try {
          await store.write(owner, {});
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
        if (!_restored) {
          final saved = await store.read(owner);
          if (_disposed) return;
          if (saved['location'] != null) {
            try {
              final value = HomeLocation.fromJson(Map<String, dynamic>.from(
                  jsonDecode(saved['location']!) as Map));
              if (value.valid) location = value;
            } catch (_) {
              await store.write(owner, {});
            }
          }
          _restored = true;
        }
        // Home remains usable without location permission or a saved address.
        await _fetch();
        if (_disposed) return;
        try {
          final rows =
              (await addressesApi.addressesControllerList()).data!.items;
          if (_disposed) return;
          addresses = rows;
          if (location == null) {
            for (final row in rows) {
              if (row.isDefault) {
                location = HomeLocation.saved(row);
                break;
              }
            }
          }
        } catch (error) {
          final mapped = error is DioException
              ? mapDioFailure(error)
              : const UnknownFailure();
          if (mapped is UnauthorizedFailure || mapped is ForbiddenFailure) {
            throw mapped;
          }
          // Location selection can still be entered manually if address loading fails.
          failure = mapped;
        }
      });
  Future<void> _fetch({String? cursor}) async {
    if (_disposed) return;
    var next = (await api.homeControllerGet(limit: 20, cursor: cursor)).data!;
    if (_disposed) return;
    if (cursor != null &&
        home != null &&
        next.businessDate != home!.businessDate) {
      next = (await api.homeControllerGet(limit: 20)).data!;
      cursor = null;
      if (_disposed) return;
    }
    if (cursor != null && home != null) {
      final rows = {
        for (final row in home!.deliveries) row.id: row,
        for (final row in next.deliveries) row.id: row
      };
      next = CustomerHome(
          serverTime: next.serverTime,
          businessDate: next.businessDate,
          categories: next.categories,
          deliveries: rows.values.toList(),
          nextCursor: next.nextCursor);
    }
    home = next;
    stale = false;
  }

  Future<void> more() => _run(() async {
        final cursor = home?.nextCursor;
        if (cursor == null) return;
        try {
          await _fetch(cursor: cursor);
        } on DioException catch (error) {
          if (mapDioFailure(error).code != 'INVALID_CURSOR') rethrow;
          await _fetch();
        }
      });
  Future<bool> select(HomeLocation value) async {
    if (busy || _disposed || !value.valid) return false;
    await _run(() async {
      await store.write(owner, {'location': jsonEncode(value.toJson())});
      if (!_disposed) location = value;
    });
    return !_disposed && failure == null;
  }
}

final homeSearchProvider = ChangeNotifierProvider.autoDispose
    .family<HomeSearchController, String?>((ref, category) {
  ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final scope = ref.watch(homeProvider.select((m) => (m.owner, m.location)));
  final client = homeClient(ref);
  ref.onDispose(client.close);
  return HomeSearchController(DiscoveryApi(client.dio), scope.$2, category,
      ref.read(onboardingDraftsProvider), '${scope.$1}:searches');
});

class HomeSearchController extends ChangeNotifier {
  HomeSearchController(
      this.api, this.location, this.category, this.store, this.owner);
  final DiscoveryApi api;
  final HomeLocation? location;
  final String? category;
  final OnboardingDrafts store;
  final String owner;
  List<String> recent = [];
  bool _restored = false;
  List<DiscoveredVendor> items = [];
  AppFailure? failure;
  String term = '', _cursor = '';
  bool busy = false, ready = false, _disposed = false;
  bool get hasMore => _cursor.isNotEmpty;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> search(String value, {bool more = false}) async {
    if (_disposed || busy || location == null) return;
    if (value.trim().length > 120) return;
    busy = true;
    failure = null;
    if (!more) {
      term = value.trim();
      items = [];
      ready = false;
      _cursor = '';
    }
    notifyListeners();
    try {
      if (!_restored) {
        final saved = await store.read(owner);
        if (_disposed) return;
        final rows = jsonDecode(saved['recent'] ?? '[]') as List;
        recent = rows
            .whereType<String>()
            .where((s) => s.isNotEmpty && s.length <= 120)
            .take(10)
            .toList();
        _restored = true;
      }
      final page = (await api.discoveryControllerSearch(
              lat: location!.latitude,
              lng: location!.longitude,
              pincode: location!.pincode,
              category: category,
              q: term,
              limit: 20,
              cursor: more ? _cursor : null))
          .data!;
      if (_disposed) return;
      if (term.isNotEmpty && !more) {
        recent = [term, ...recent.where((s) => s != term)].take(10).toList();
        await store.write(owner, {'recent': jsonEncode(recent)});
        if (_disposed) return;
      }
      items = {
        for (final row in items) row.id: row,
        for (final row in page.items) row.id: row
      }.values.toList();
      _cursor = page.nextCursor ?? '';
      ready = true;
    } catch (error) {
      if (_disposed) return;
      failure =
          error is DioException ? mapDioFailure(error) : const UnknownFailure();
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        items = [];
        ready = false;
        _cursor = '';
        recent = [];
        try {
          await store.write(owner, {});
        } catch (_) {
          failure = const UnknownFailure(code: 'CACHE_CLEAR_FAILED');
        }
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }
}
