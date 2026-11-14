// T-051: account-scoped owned history, explicit durable cancellation recovery.
import 'dart:async';
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
import '../notifications/order_notices.dart';

final customerOrdersProvider =
    ChangeNotifierProvider<CustomerOrdersController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final client = homeClient(ref);
  ref.onDispose(client.close);
  final model = CustomerOrdersController(
      CustomerOrdersApi(client.dio),
      ref.read(onboardingDraftsProvider),
      '${ref.read(authConfigProvider).baseUrl}:${identity.$1}:customer-orders');
  listenForOrderNotices(ref, identity.$1, 'CUSTOMER', model.refreshFromNotice);
  return model;
});

class CustomerOrdersController extends ChangeNotifier {
  CustomerOrdersController(this.api, this.store, this.owner);
  final CustomerOrdersApi api;
  final OnboardingDrafts store;
  final String owner;
  List<OrderResult> items = [];
  final details = <String, OrderDetail>{}, fresh = <String>{};
  String tab = 'ALL';
  String? activeId;
  int total = 0, offset = 0;
  Map<String, dynamic>? pending;
  AppFailure? failure;
  bool busy = false,
      ready = false,
      stale = true,
      _restored = false,
      _disposed = false;
  Future<void> _idle = Future.value();
  bool get alive => !_disposed;
  bool canActOn(String id) =>
      !_disposed && !busy && pending == null && !stale && fresh.contains(id);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _persist() => store.write(owner, {
        'items': jsonEncode(items.take(100).map((o) => o.toJson()).toList()),
        'total': '$total',
        'tab': tab,
        'details':
            jsonEncode(details.values.take(20).map((o) => o.toJson()).toList()),
        if (pending != null) 'pending': jsonEncode(pending)
      });
  Future<void> _restore() async {
    if (_restored || _disposed) return;
    final data = await store.read(owner);
    if (_disposed) return;
    items = (jsonDecode(data['items'] ?? '[]') as List)
        .map((j) => OrderResult.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
    total = int.tryParse(data['total'] ?? '') ?? items.length;
    offset = items.length;
    tab = ['ALL', 'ONGOING', 'DELIVERED', 'CANCELLED'].contains(data['tab'])
        ? data['tab']!
        : 'ALL';
    for (final j in jsonDecode(data['details'] ?? '[]') as List) {
      final o = OrderDetail.fromJson(Map<String, dynamic>.from(j as Map));
      details[o.id] = o;
    }
    pending = data['pending'] == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(data['pending']!) as Map);
    ready = data.containsKey('items');
    stale = true;
    _restored = true;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_disposed) return;
    if (busy) {
      await _idle;
      if (!_disposed) await _run(action);
      return;
    }
    final done = Completer<void>();
    _idle = done.future;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await _restore();
      if (!_disposed) await action();
    } catch (error) {
      if (_disposed) return;
      failure = error is DioException
          ? mapDioFailure(error)
          : error is AppFailure
              ? error
              : const UnknownFailure();
      stale = true;
      fresh.clear();
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        items = [];
        details.clear();
        total = 0;
        offset = 0;
        ready = false;
        pending = null;
        try {
          await _persist();
        } catch (_) {
          failure = const UnknownFailure(code: 'CACHE_CLEAR_FAILED');
        }
      }
    } finally {
      busy = false;
      done.complete();
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _list({bool more = false}) async {
    final result = (await api.customerOrdersControllerList(
            tab: tab, limit: 20, offset: more ? offset : 0))
        .data!;
    if (_disposed) return;
    final next = more ? List<OrderResult>.of(items) : <OrderResult>[];
    final ids = next.map((o) => o.id).toSet();
    next.addAll(result.items.where((o) => ids.add(o.id)));
    items = next;
    offset = (more ? offset : 0) + result.items.length;
    total = result.total;
    ready = true;
    stale = false;
    await _persist();
  }

  Future<void> load({String? filter, bool more = false}) => _run(() async {
        if (filter != null && filter != tab) {
          tab = filter;
          items = [];
          offset = 0;
          total = 0;
          ready = false;
          stale = true;
        }
        if (!more || offset < total) await _list(more: more);
      });
  Future<void> _detail(String id) async {
    fresh.remove(id);
    try {
      final result = (await api.customerOrdersControllerDetail(id: id)).data!;
      if (_disposed) return;
      if (result.id != id) throw const UnknownFailure();
      details.remove(id);
      details[id] = result;
      while (details.length > 20) {
        details.remove(details.keys.first);
      }
      fresh.add(id);
      stale = false;
      await _persist();
    } on DioException catch (error) {
      if (!_disposed && error.response?.statusCode == 404) {
        details.remove(id);
        await _persist();
      }
      rethrow;
    }
  }

  Future<void> open(String id) {
    activeId = id;
    return _run(() => _detail(id));
  }

  void leave(String id) {
    if (activeId == id) activeId = null;
  }

  Future<void> refreshFromNotice() => _run(() async {
        // A trusted owned notice triggers fresh reads, never a direct state change.
        if (activeId != null) await _detail(activeId!);
        if (!_disposed) await _list();
      });
  Future<void> cancel(String id) async {
    if (!canActOn(id) || details[id]?.status != 'NEW') return;
    final version = details[id]!.version;
    await _run(() async {
      pending = {'id': id, 'key': const Uuid().v4(), 'version': version};
      await _persist();
      if (!_disposed) await _send();
    });
  }

  Future<void> retry() => _run(() async {
        if (pending != null) {
          await _persist();
          if (!_disposed) await _send();
        }
      });
  Future<void> _send() async {
    final saved = pending;
    if (saved == null || _disposed) return;
    final id = saved['id'] as String;
    try {
      final result = (await api.customerOrdersControllerCancel(
              id: id,
              idempotencyKey: saved['key'] as String,
              orderCancelInput:
                  OrderCancelInput(version: saved['version'] as int)))
          .data!;
      if (_disposed) return;
      if (result.id != id) throw const UnknownFailure();
    } on DioException catch (error) {
      if (_disposed) rethrow;
      if ([400, 404, 409, 422].contains(error.response?.statusCode)) {
        pending = null;
        try {
          await _persist();
        } catch (_) {
          pending = saved;
          rethrow;
        }
        if (error.response?.statusCode == 409) {
          await _detail(id);
          if (!_disposed) await _list();
        }
        if (error.response?.statusCode == 404) {
          details.remove(id);
          fresh.remove(id);
          await _persist();
        }
      }
      rethrow;
    }
    if (_disposed) return;
    pending = null;
    fresh.remove(id);
    try {
      await _persist();
    } catch (_) {
      pending = saved;
      rethrow;
    }
    await _detail(id);
    if (!_disposed) await _list();
  }

  Future<OrderReorder?> reorder(String id) async {
    if (!canActOn(id) ||
        !['DELIVERED', 'FAILED', 'REJECTED', 'CANCELLED']
            .contains(details[id]?.status)) {
      return null;
    }
    OrderReorder? result;
    await _run(() async {
      final preview = (await api.customerOrdersControllerReorder(id: id)).data!;
      if (preview.vendorId != details[id]?.vendorId) {
        throw const UnknownFailure();
      }
      if (!_disposed) result = preview;
    });
    return result;
  }
}
