import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import '../../core/network/app_failure.dart';
import '../home/home_controller.dart';
import '../auth/session_controller.dart';

typedef DiscoveryFilter = ({String? category, bool favorites});
final discoveryProvider = ChangeNotifierProvider.autoDispose
    .family<DiscoveryController, DiscoveryFilter>((ref, filter) {
  ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final scope = ref.watch(homeProvider.select((m) => (m.owner, m.location)));
  final client = homeClient(ref);
  ref.onDispose(client.close);
  return DiscoveryController(DiscoveryApi(client.dio), scope.$2, filter);
});

class DiscoveryController extends ChangeNotifier {
  DiscoveryController(this.api, this.location, this.filter);
  final DiscoveryApi api;
  final HomeLocation? location;
  final DiscoveryFilter filter;
  List<DiscoveredVendor> items = [];
  String sort = 'NEARBY';
  String? cursor;
  bool busy = false, ready = false, _disposed = false;
  AppFailure? failure;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load({String? order, bool more = false}) async {
    if (_disposed || busy || location == null) return;
    if (order != null) sort = order;
    busy = true;
    failure = null;
    if (!more) {
      items = [];
      cursor = null;
      ready = false;
    }
    notifyListeners();
    try {
      final response = filter.favorites
          ? await api.discoveryControllerFavorites(
              lat: location!.latitude,
              lng: location!.longitude,
              pincode: location!.pincode,
              category: filter.category,
              sort: sort,
              limit: 20,
              cursor: more ? cursor : null)
          : await api.discoveryControllerList(
              lat: location!.latitude,
              lng: location!.longitude,
              pincode: location!.pincode,
              category: filter.category,
              sort: sort,
              limit: 20,
              cursor: more ? cursor : null);
      if (_disposed) return;
      final page = response.data!;
      items = {
        for (final r in items) r.id: r,
        for (final r in page.items) r.id: r
      }.values.toList();
      cursor = page.nextCursor;
      ready = true;
    } catch (e) {
      if (_disposed) return;
      failure = e is DioException ? mapDioFailure(e) : const UnknownFailure();
      if (failure is ForbiddenFailure ||
          failure is UnauthorizedFailure ||
          failure is NotFoundFailure) {
        items = [];
        ready = false;
        cursor = null;
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }
}

final vendorProvider = ChangeNotifierProvider.autoDispose
    .family<VendorController, String>((ref, id) {
  ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final scope = ref.watch(homeProvider.select((m) => (m.owner, m.location)));
  final client = homeClient(ref);
  ref.onDispose(client.close);
  return VendorController(DiscoveryApi(client.dio), scope.$2, id);
});

class VendorController extends ChangeNotifier {
  VendorController(this.api, this.location, this.id);
  final DiscoveryApi api;
  final HomeLocation? location;
  final String id;
  VendorAbout? about;
  List<ProductResponse> products = [];
  AppFailure? failure;
  bool busy = false, _disposed = false;
  final _images = <String, Future<Uint8List?>>{};
  ProductResponse? product(String productId) {
    for (final p in products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _images.clear();
    super.dispose();
  }

  Future<void> load() async {
    if (busy || _disposed || location == null) return;
    busy = true;
    failure = null;
    about = null;
    products = [];
    _images.clear();
    notifyListeners();
    try {
      final a = (await api.discoveryControllerAbout(
              id: id,
              lat: location!.latitude,
              lng: location!.longitude,
              pincode: location!.pincode))
          .data!;
      final p = (await api.discoveryControllerProducts(
              id: id,
              lat: location!.latitude,
              lng: location!.longitude,
              pincode: location!.pincode))
          .data!;
      if (_disposed) return;
      about = a;
      products = p.items;
    } catch (e) {
      if (!_disposed) {
        failure = e is DioException ? mapDioFailure(e) : const UnknownFailure();
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<ProductResponse?> fresh(String productId) async {
    if (_disposed || busy || location == null) return null;
    try {
      final rows = (await api.discoveryControllerProduct(
              id: id,
              productId: productId,
              lat: location!.latitude,
              lng: location!.longitude,
              pincode: location!.pincode))
          .data!
          .items;
      if (_disposed) return null;
      final next = rows.single;
      products = [
        for (final p in products)
          if (p.id == next.id) next else p
      ];
      notifyListeners();
      return next;
    } catch (e) {
      if (!_disposed) {
        failure = e is DioException ? mapDioFailure(e) : const UnknownFailure();
        about = null;
        products = [];
        _images.clear();
        notifyListeners();
      }
      return null;
    }
  }

  Future<Uint8List?> image(String mediaId) =>
      _images.putIfAbsent(mediaId, () async {
        if (_disposed || location == null) return null;
        try {
          final data = (await api.discoveryControllerImage(
                  id: id,
                  mediaId: mediaId,
                  lat: location!.latitude,
                  lng: location!.longitude,
                  pincode: location!.pincode))
              .data;
          return _disposed ? null : data;
        } catch (_) {
          return null;
        }
      });
}
