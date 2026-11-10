// T-027 / US-030–US-032: server-authoritative catalog and encrypted account cache.
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

final productsProvider =
    ChangeNotifierProvider.autoDispose<ProductsController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  final model = ProductsController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:products');
  ref.onDispose(client.close);
  if (identity.$1 != null && identity.$2 == 'VENDOR') {
    Future.microtask(model.load);
  }
  return model;
});

class ProductsController extends ChangeNotifier {
  ProductsController(this.client, this.store, this.owner)
      : api = CatalogApi(client.dio),
        media = MediaApi(client.dio);
  final NetworkClient client;
  final CatalogApi api;
  final MediaApi media;
  final OnboardingDrafts store;
  final String owner;
  List<ProductResponse> products = [];
  List<String> types = [];
  AppFailure? failure;
  bool busy = false, cached = false, ready = false, _disposed = false;
  Map<String, dynamic>? pending;
  String search = '', filter = 'ALL';
  bool get canEdit =>
      !_disposed && ready && !cached && !busy && pending == null;
  List<ProductResponse> get visible => products
      .where((p) =>
          p.name.toLowerCase().contains(search.toLowerCase()) &&
          (filter == 'ALL' || p.productType == filter))
      .toList();
  void query(String value, String type) {
    search = value;
    filter = type;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }

  Future<void> _persist(
          {Map<String, dynamic>? request,
          required List<ProductResponse> rows}) =>
      store.write(owner, {
        'products': jsonEncode(rows.map((p) => p.toJson()).toList()),
        'types': jsonEncode(types),
        if (request != null) 'pending': jsonEncode(request),
      });
  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      if (!_disposed) {
        failure = error is DioException
            ? mapDioFailure(error)
            : error is AppFailure
                ? error
                : const UnknownFailure();
        if (failure is NetworkFailure || failure is TimeoutFailure) {
          cached = ready;
        }
        if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
          products = [];
          types = [];
          ready = false;
          pending = null;
          filter = 'ALL';
          search = '';
          // Never show cached account data after a definitive authorization denial.
          try {
            await store.write(owner, {});
          } catch (_) {
            failure = const UnknownFailure(code: 'CACHE_CLEAR_FAILED');
          }
        }
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> load() => _run(() async {
        final saved = await store.read(owner);
        if (_disposed) return;
        if (!ready) {
          products = ((jsonDecode(saved['products'] ?? '[]')) as List)
              .map((v) =>
                  ProductResponse.fromJson(Map<String, dynamic>.from(v as Map)))
              .toList();
          types = (jsonDecode(saved['types'] ?? '[]') as List).cast<String>();
          pending = saved['pending'] == null
              ? null
              : Map<String, dynamic>.from(jsonDecode(saved['pending']!) as Map);
          ready = saved.containsKey('products');
          cached = ready;
          notifyListeners();
        }
        // Cache is a complete catalog snapshot, so local search/filter is never page-limited.
        final options = (await api.catalogControllerOptions()).data!;
        final rows = <String, ProductResponse>{};
        var offset = 0;
        while (true) {
          final page =
              (await api.catalogControllerList(limit: 100, offset: offset))
                  .data!;
          if (_disposed) return;
          for (final row in page.items) {
            rows[row.id] = row;
          }
          offset += page.items.length;
          if (offset >= page.total) break;
          if (page.items.isEmpty) {
            throw const ServerFailure(code: 'CATALOG_CHANGED');
          }
        }
        if (_disposed) return;
        types = options.productTypes;
        await _persist(request: pending, rows: rows.values.toList());
        if (_disposed) return;
        products = rows.values.toList();
        ready = true;
        cached = false;
      });
  Future<void> save(Map<String, dynamic> fields, {String? id}) =>
      _begin(id == null ? 'create' : 'edit', id, fields);
  Future<void> adjust(String id, int delta, String reason) =>
      _begin('adjust', id, {'delta': delta, 'reason': reason.trim()});
  Future<void> remove(String id) => _begin('delete', id, {});
  Future<void> _begin(String action, String? id, Map<String, dynamic> body) =>
      _run(() async {
        if (!ready || cached || pending != null) throw const NetworkFailure();
        pending = {
          'action': action,
          'id': id,
          'body': body,
          'key': const Uuid().v4()
        };
        await _sendPending();
      });
  Future<void> retryPending() => _run(_sendPending);
  Future<void> _sendPending() async {
    final request = pending;
    if (request == null || _disposed) return;
    // Persist the exact payload/key before sending; interrupted writes replay explicitly.
    await _persist(request: request, rows: products);
    if (_disposed) return;
    final body = Map<String, dynamic>.from(request['body'] as Map);
    final id = request['id'] as String?, key = request['key'] as String;
    ProductResponse? result;
    try {
      switch (request['action']) {
        case 'create':
          result = (await api.catalogControllerCreate(
                  idempotencyKey: key,
                  productInput: ProductInput.fromJson(body)))
              .data!;
        case 'edit':
          // Generated PATCH serializers omit explicit nulls and supply stock defaults.
          // A full editor payload uses the shared transport and generated response model
          // to preserve clearing optional values without resetting stock accidentally.
          final response = await client.request<Map<String, dynamic>>(
              '/api/v1/vendor/products/$id',
              data: body,
              options:
                  Options(method: 'PATCH', headers: {'Idempotency-Key': key}));
          result = ProductResponse.fromJson(response.data!);
        case 'adjust':
          result = (await api.catalogControllerAdjust(
                  id: id!,
                  idempotencyKey: key,
                  stockAdjustment: StockAdjustment.fromJson(body)))
              .data!;
        case 'delete':
          await api.catalogControllerRemove(id: id!, idempotencyKey: key);
        default:
          throw const UnknownFailure();
      }
    } catch (error) {
      final f = error is DioException ? mapDioFailure(error) : error;
      if (f is ValidationFailure ||
          f is ConflictFailure ||
          f is NotFoundFailure ||
          f is BusinessRuleFailure) {
        // Definitive rejections can be edited; ambiguous transport/server outcomes retain key.
        await _persist(rows: products);
        pending = null;
      }
      rethrow;
    }
    if (_disposed) return;
    final next = [
      ...products.where((p) => p.id != (result?.id ?? id)),
      if (result != null) result
    ];
    await _persist(rows: next);
    if (_disposed) return;
    products = next;
    pending = null;
    cached = false;
  }

  Future<String?> upload(Uint8List bytes, String key) async {
    if (!canEdit || bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      return null;
    }
    String? id;
    await _run(() async {
      final png = bytes.first == 137;
      id = (await media.mediaControllerUpload(
              idempotencyKey: key,
              purpose: 'PRODUCT_IMAGE',
              file: MultipartFile.fromBytes(bytes,
                  filename: png ? 'product.png' : 'product.jpg',
                  contentType:
                      DioMediaType.parse(png ? 'image/png' : 'image/jpeg'))))
          .data!
          .mediaId;
    });
    return _disposed ? null : id;
  }

  Future<Uint8List> image(String id) async =>
      (await media.mediaControllerContent(id: id)).data!;
}

/// RULE-01: parse decimal text directly to integer paise, never through double.
int? parseProductPaise(String text) {
  if (!RegExp(r'^\d{1,8}(?:\.\d{1,2})?$').hasMatch(text.trim())) return null;
  final parts = text.trim().split('.');
  final value = int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  return value <= 2147483647 ? value : null;
}
