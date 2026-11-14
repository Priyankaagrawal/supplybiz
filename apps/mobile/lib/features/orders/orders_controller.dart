// T-048 / FR-040–045: owned reads and permanent, encrypted transition recovery.
import 'dart:convert';
import 'dart:async';
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

final vendorOrdersProvider =
    ChangeNotifierProvider<VendorOrdersController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final client = homeClient(ref);
  final model = VendorOrdersController(
      VendorOrdersApi(client.dio),
      ref.read(onboardingDraftsProvider),
      '${ref.read(authConfigProvider).baseUrl}:${identity.$1}:vendor-orders');
  ref.onDispose(client.close);
  listenForOrderNotices(ref, identity.$1, 'VENDOR', model.refreshFromNotice);
  return model;
});

class VendorOrdersController extends ChangeNotifier {
  VendorOrdersController(this.api, this.store, this.owner);
  final VendorOrdersApi api;
  final OnboardingDrafts store;
  final String owner;
  List<OrderResult> items = [];
  final details = <String, OrderDetail>{}, fresh = <String>{};
  String status = 'ALL', search = '';
  DateTime? date;
  String? activeId;
  int total = 0, offset = 0;
  Map<String, dynamic>? pending;
  AppFailure? failure;
  bool busy = false,
      ready = false,
      stale = true,
      completed = false,
      _restored = false,
      _disposed = false;
  Future<void> _idle = Future<void>.value();
  bool get canAct => !busy && pending == null && !_disposed;
  bool canActOn(String id) => canAct && fresh.contains(id) && !stale;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _persist() => store.write(owner, {
        'items': jsonEncode(items.take(100).map((i) => i.toJson()).toList()),
        'total': '$total',
        'status': status,
        'search': search,
        if (date != null) 'date': date!.toIso8601String().substring(0, 10),
        'details':
            jsonEncode(details.values.take(20).map((d) => d.toJson()).toList()),
        if (pending != null) 'pending': jsonEncode(pending),
      });
  Future<void> _restore() async {
    if (_restored || _disposed) return;
    final saved = await store.read(owner);
    if (_disposed) return;
    items = (jsonDecode(saved['items'] ?? '[]') as List)
        .map((i) => OrderResult.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();
    total = int.tryParse(saved['total'] ?? '') ?? items.length;
    offset = items.length;
    status = saved['status'] ?? 'ALL';
    search = saved['search'] ?? '';
    date = DateTime.tryParse(saved['date'] ?? '');
    for (final row in jsonDecode(saved['details'] ?? '[]') as List) {
      final d = OrderDetail.fromJson(Map<String, dynamic>.from(row as Map));
      details[d.id] = d;
    }
    pending = saved['pending'] == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(saved['pending']!) as Map);
    ready = saved.containsKey('items');
    stale = true;
    _restored = true;
    notifyListeners();
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
    completed = false;
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
      if (failure is NetworkFailure ||
          failure is TimeoutFailure ||
          failure is ServerFailure ||
          failure is UnknownFailure) {
        stale = true;
        fresh.clear();
      }
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        items = [];
        details.clear();
        fresh.clear();
        search = '';
        status = 'ALL';
        date = null;
        total = 0;
        ready = false;
        stale = true;
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

  Future<void> _fetchList({bool more = false}) async {
    final page = (await api.vendorOrdersControllerList(
            status: status,
            q: search,
            date: date,
            limit: 20,
            offset: more ? offset : 0))
        .data!;
    if (_disposed) return;
    final next = more ? List<OrderResult>.of(items) : <OrderResult>[];
    final ids = next.map((i) => i.id).toSet();
    next.addAll(page.items.where((i) => ids.add(i.id)));
    offset = (more ? offset : 0) + page.items.length;
    items = next;
    total = page.total;
    ready = true;
    stale = false;
    await _persist();
  }

  Future<void> load(
          {String? filter,
          String? query,
          DateTime? day,
          bool clearDate = false,
          bool more = false}) =>
      _run(() async {
        if (more) {
          if (offset < total) await _fetchList(more: true);
          return;
        }
        final nextStatus = filter ?? status,
            nextSearch = (query ?? search).trim(),
            nextDate = clearDate ? null : day ?? date;
        if (nextStatus != status || nextSearch != search || nextDate != date) {
          items = [];
          total = 0;
          offset = 0;
          ready = false;
          stale = true;
        }
        status = nextStatus;
        search = nextSearch;
        date = nextDate;
        await _fetchList();
      });
  Future<void> open(String id) => _run(() async {
        activeId = id;
        await _fetchDetail(id);
      });
  Future<void> refreshFromNotice() => _run(() async {
        if (activeId != null) await _fetchDetail(activeId!);
        if (!_disposed) await _fetchList();
      });
  Future<void> _fetchDetail(String id) async {
    fresh.remove(id);
    try {
      final data = (await api.vendorOrdersControllerDetail(id: id)).data!;
      if (_disposed) return;
      if (data.id != id) throw const UnknownFailure();
      details.remove(id);
      details[id] = data;
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

  Future<void> act(String id, String to, {String? reason, String? text}) async {
    if (!canActOn(id)) return;
    final detail = details[id];
    if (detail == null) return;
    const allowed = {
      'NEW': ['ACCEPTED', 'REJECTED'],
      'ACCEPTED': ['PREPARING', 'OUT_FOR_DELIVERY'],
      'PREPARING': ['OUT_FOR_DELIVERY']
    };
    if (allowed[detail.status]?.contains(to) != true) return;
    final explanation = text?.trim();
    if (to == 'REJECTED' &&
        (![
              'CUSTOMER_UNAVAILABLE',
              'OUT_OF_STOCK',
              'NOT_SERVICEABLE',
              'CUSTOMER_REQUEST',
              'OTHER'
            ].contains(reason) ||
            reason == 'OTHER' &&
                (explanation == null ||
                    explanation.length < 5 ||
                    explanation.length > 200))) {
      failure = const BusinessRuleFailure(code: 'REJECT_REASON_REQUIRED');
      notifyListeners();
      return;
    }
    await _run(() async {
      pending = {
        'id': id,
        'key': const Uuid().v4(),
        'body': {
          'to': to,
          'version': detail.version,
          if (reason != null) 'reason': reason,
          if (reason == 'OTHER') 'reasonText': explanation
        }
      };
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
      final result = (await api.vendorOrdersControllerTransition(
              id: id,
              idempotencyKey: saved['key'] as String,
              orderTransitionInput: OrderTransitionInput.fromJson(
                  Map<String, dynamic>.from(saved['body'] as Map))))
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
          await _fetchDetail(id);
          await _fetchList();
        }
        if (error.response?.statusCode == 404) {
          details.remove(id);
          fresh.remove(id);
          await _persist();
          await _fetchList();
        }
      }
      rethrow;
    }
    if (_disposed) return;
    completed = true;
    pending = null;
    fresh.remove(id);
    try {
      await _persist();
    } catch (_) {
      pending = saved;
      rethrow;
    }
    await _fetchDetail(id);
    if (!_disposed) await _fetchList();
  }
}
