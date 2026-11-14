// T-050: S-V-16/S-V-34. A single SQLCipher snapshot atomically saves cache + outbox.
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';
import 'package:device_coordination/device_coordination.dart';
import '../../core/network/app_failure.dart';
import '../auth/session_controller.dart';
import '../home/home_controller.dart';
import '../onboarding/onboarding_controller.dart';
import 'delivery_background.dart';

final deliveriesProvider = ChangeNotifierProvider<DeliveriesController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final client = homeClient(ref);
  ref.onDispose(client.close);
  return DeliveriesController(client.dio, ref.read(onboardingDraftsProvider),
      '${ref.read(authConfigProvider).baseUrl}:${identity.$1}:deliveries',
      coordinated: true, schedule: scheduleDeliverySync);
});

class DeliveryAction {
  DeliveryAction(this.id, this.orderNo, this.key, this.body, this.createdAt,
      {this.state = 'PENDING', this.attempts = 0, this.nextAt, this.code});
  final String id, orderNo, key, createdAt;
  final Map<String, dynamic> body;
  String state;
  int attempts;
  DateTime? nextAt;
  String? code;
  bool get rejected => state == 'REJECTED';
  bool get retryable => state == 'RETRYABLE';
  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNo': orderNo,
        'key': key,
        'body': body,
        'createdAt': createdAt,
        'state': state,
        'attempts': attempts,
        'nextAt': nextAt?.toIso8601String(),
        'code': code,
      };
  factory DeliveryAction.fromJson(Map<String, dynamic> j) => DeliveryAction(
      j['id'] as String,
      j['orderNo'] as String,
      j['key'] as String,
      Map<String, dynamic>.from(j['body'] as Map),
      j['createdAt'] as String,
      // SENDING is an uncertain result; replay exactly the saved body/key.
      state: j['state'] == 'SENDING' ? 'PENDING' : j['state'] as String,
      attempts: j['attempts'] as int,
      nextAt: DateTime.tryParse(j['nextAt'] as String? ?? ''),
      code: j['code'] as String?);
}

class DeliveriesController extends ChangeNotifier {
  DeliveriesController(this.dio, this.store, this.owner,
      {this.coordinated = false, this.schedule});
  final Dio dio;
  final OnboardingDrafts store;
  final String owner;
  final bool coordinated;
  final Future<void> Function()? schedule;
  String? _savedSnapshot;
  bool _recoveryScheduled = false;
  final cache = <String, List<OrderDetail>>{};
  final queue = <DeliveryAction>[];
  String? date;
  String filter = 'ALL';
  bool busy = false, stale = true, restored = false, _disposed = false;
  bool _storageFailed = false;
  AppFailure? failure;
  Future<void> _tail = Future.value();
  List<OrderDetail> get rows => cache[date] ?? [];
  String status(OrderDetail row) =>
      queue.where((a) => a.id == row.id && !a.rejected).lastOrNull?.body['to']
          as String? ??
      row.status;
  bool pending(String id) => queue.any((a) => a.id == id && !a.rejected);
  bool canAct(String id) =>
      !busy &&
      !_storageFailed &&
      !queue.any((a) => a.id == id && (a.rejected || a.retryable));
  List<OrderDetail> get visible => rows
      .where((r) =>
          filter == 'ALL' ||
          status(r) == (filter == 'PENDING' ? 'ACCEPTED' : filter))
      .toList();
  int count(String tab) => rows
      .where((r) =>
          tab == 'ALL' || status(r) == (tab == 'PENDING' ? 'ACCEPTED' : tab))
      .length;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() async {
    if (_disposed) return;
    final snapshot = jsonEncode({
      'date': date,
      'cache': cache
          .map((d, rows) => MapEntry(d, rows.map((r) => r.toJson()).toList())),
      'queue': queue.map((a) => a.toJson()).toList(),
    });
    await store.write(owner, {'snapshot': snapshot});
    _savedSnapshot = snapshot;
  }

  Future<void> _restore() async {
    if (_disposed) return;
    final saved = await store.read(owner);
    if (_disposed) return;
    if (restored && saved['snapshot'] == _savedSnapshot) return;
    cache.clear();
    queue.clear();
    date = null;
    _savedSnapshot = saved['snapshot'];
    if (saved['snapshot'] != null) {
      final j = jsonDecode(saved['snapshot']!) as Map;
      date = j['date'] as String?;
      for (final entry in (j['cache'] as Map).entries) {
        cache[entry.key as String] = (entry.value as List)
            .map((v) =>
                OrderDetail.fromJson(Map<String, dynamic>.from(v as Map)))
            .toList();
      }
      queue.addAll((j['queue'] as List).map(
          (a) => DeliveryAction.fromJson(Map<String, dynamic>.from(a as Map))));
    }
    restored = true;
  }

  Future<void> _run(Future<void> Function() action) {
    Future<void> operation() async {
      if (_disposed) return;
      busy = true;
      failure = null;
      _notify();
      try {
        await _restore();
        if (!_recoveryScheduled &&
            queue.any((a) => !a.rejected && !a.retryable)) {
          await schedule?.call();
          _recoveryScheduled = true;
        }
        if (!_disposed) await action();
      } catch (e) {
        if (_disposed) return;
        failure = e is DioException
            ? mapDioFailure(e)
            : e is AppFailure
                ? e
                : const UnknownFailure();
        stale = true;
        if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
          cache.clear();
          // Preserve uncertain financial actions, but never automatically resend
          // after an authorization failure. Explicit retry rechecks the server.
          for (final a in queue.where((a) => !a.rejected)) {
            a.state = 'RETRYABLE';
          }
          try {
            await _persist();
          } catch (_) {
            _storageFailed = true;
            failure = const UnknownFailure(code: 'CACHE_CLEAR_FAILED');
          }
        }
      } finally {
        busy = false;
        _notify();
      }
    }

    final result = _tail
        .then((_) =>
            coordinated ? DeviceCoordination.exclusive(operation) : operation())
        .catchError((Object _) {
      if (!_disposed) {
        failure = const UnknownFailure(code: 'SYNC_COORDINATION_UNAVAILABLE');
        stale = true;
        _notify();
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> load({String? day}) => _run(() async {
        if (day != null) date = day;
        await _fetch();
      });
  Future<void> _fetch() async {
    final api = VendorDeliveriesApi(dio);
    final next = <OrderDetail>[];
    DeliveryList? page;
    do {
      page = (await api.vendorDeliveriesControllerList(
              date: date == null ? null : DateTime.parse(date!),
              status: 'ALL',
              limit: 50,
              offset: next.length))
          .data!;
      if (_disposed) return;
      next.addAll(page.items);
      if (page.items.isEmpty) break;
    } while (next.length < page.total);
    date = page.deliveryDate;
    cache[date!] = next;
    final today = DateTime.parse(page.businessDate);
    cache.removeWhere((d, _) =>
        DateTime.parse(d).difference(today).inDays.abs() > 7 && d != date);
    stale = false;
    await _persist();
  }

  void select(String tab) {
    filter = tab;
    _notify();
  }

  Future<void> enqueue(OrderDetail row, String to,
          {String? reason, Map<String, dynamic>? payment}) =>
      _run(() async {
        // A headless worker may have advanced the cached base while this card's
        // sheet was open. Preserve the intent, but use the freshly leased base.
        final current = rows.where((r) => r.id == row.id).firstOrNull;
        if (_storageFailed ||
            current == null ||
            queue.any((a) => a.id == row.id && (a.rejected || a.retryable))) {
          return;
        }
        const transitions = {
          'ACCEPTED': ['PREPARING', 'OUT_FOR_DELIVERY'],
          'PREPARING': ['OUT_FOR_DELIVERY'],
          'OUT_FOR_DELIVERY': ['DELIVERED', 'FAILED'],
        };
        if (transitions[status(current)]?.contains(to) != true) return;
        if (to == 'FAILED' &&
            ((reason?.trim().isEmpty ?? true) || reason!.trim().length > 200)) {
          throw const BusinessRuleFailure(code: 'FAIL_REASON_REQUIRED');
        }
        if (to == 'DELIVERED') {
          final collected = payment?['collected'];
          final amount = BigInt.tryParse('${payment?['amountPaise']}');
          if (collected is! bool ||
              collected &&
                  (!['CASH', 'UPI', 'BANK', 'WALLET']
                          .contains(payment?['method']) ||
                      !RegExp(r'^[1-9]\d{0,18}$')
                          .hasMatch('${payment?['amountPaise']}') ||
                      amount == null ||
                      amount > BigInt.parse('9223372036854775807')) ||
              !collected &&
                  (payment!.containsKey('method') ||
                      payment.containsKey('amountPaise'))) {
            throw const BusinessRuleFailure(code: 'INVALID_DELIVERY_PAYMENT');
          }
        }
        final preceding =
            queue.where((a) => a.id == row.id && !a.rejected).length;
        final createdAt = DateTime.now().toUtc().toIso8601String();
        final a = DeliveryAction(
            current.id,
            current.orderNo,
            const Uuid().v4(),
            {
              'to': to,
              'version': current.version + preceding,
              'clientCreatedAt': createdAt,
              if (to == 'FAILED') 'reason': reason!.trim(),
              if (to == 'DELIVERED')
                'payment': Map<String, dynamic>.from(payment!),
            },
            createdAt);
        queue.add(a);
        try {
          // Register before the write, under the native engine lock. Appending
          // avoids losing the wakeup when a previous worker is just finishing.
          await schedule?.call();
          await _persist();
        } catch (_) {
          queue.remove(a);
          rethrow;
        }
        if (!_disposed) await _flush();
      });
  Future<void> flush({bool retry = false}) {
    if (restored && queue.isEmpty) return Future.value();
    return _run(() async {
      if (_storageFailed) return;
      if (queue.isEmpty) return;
      if (retry) {
        await schedule?.call();
        for (final a in queue.where((a) => a.retryable)) {
          a.state = 'PENDING';
          a.attempts = 0;
          a.nextAt = null;
        }
        await _persist();
      }
      await _flush();
    });
  }

  Future<void> _flush() async {
    for (final a in List<DeliveryAction>.of(queue)) {
      if (_disposed) return;
      if (a.rejected || a.retryable) continue;
      // FIFO per order, including when a predecessor is waiting for retry.
      if (queue.takeWhile((q) => q != a).any((q) => q.id == a.id)) continue;
      if (a.nextAt?.isAfter(DateTime.now().toUtc()) ?? false) continue;
      a.state = 'SENDING';
      a.attempts++;
      try {
        await _persist();
      } catch (_) {
        _storageFailed = true;
        rethrow;
      }
      if (_disposed) return;
      OrderResult result;
      try {
        result = (await VendorOrdersApi(dio).vendorOrdersControllerTransition(
                id: a.id,
                idempotencyKey: a.key,
                orderTransitionInput: OrderTransitionInput.fromJson(a.body)))
            .data!;
        if (result.id != a.id) throw const UnknownFailure();
      } on DioException catch (e) {
        if (_disposed) return;
        if ([400, 404, 409, 410, 422].contains(e.response?.statusCode)) {
          for (final dependent in queue.where((q) => q.id == a.id)) {
            dependent.state = 'REJECTED';
            dependent.code = mapDioFailure(e).code;
          }
          await _persist();
          // Optimistic projection is already rolled back, even if refresh fails.
          try {
            await _fetch();
          } catch (_) {
            stale = true;
          }
          failure = mapDioFailure(e);
          continue;
        }
        a.state = a.attempts >= 6 ? 'RETRYABLE' : 'PENDING';
        final seconds = mapDioFailure(e) is BusinessRuleFailure
            ? (mapDioFailure(e) as BusinessRuleFailure).retryAfterSeconds
            : null;
        a.nextAt = DateTime.now()
            .toUtc()
            .add(Duration(seconds: seconds ?? (1 << a.attempts)));
        await _persist();
        rethrow;
      }
      if (_disposed) return;
      // Commit server projection and dequeue in the same encrypted write. If
      // storage fails, stop until restart; disk retains the exact SENDING key.
      for (final rows in cache.values) {
        final i = rows.indexWhere((r) => r.id == a.id);
        if (i >= 0) {
          rows[i] = OrderDetail.fromJson({
            ...rows[i].toJson(),
            ...result.toJson(),
          });
        }
      }
      queue.remove(a);
      try {
        await _persist();
      } catch (_) {
        _storageFailed = true;
        rethrow;
      }
    }
    if (!_disposed && queue.isEmpty && date != null) await _fetch();
  }

  bool canDiscard(DeliveryAction a) => a.rejected || a.attempts == 0;
  Future<void> discard(DeliveryAction a) => _run(() async {
        if (!canDiscard(a) || _storageFailed) return;
        // Discard dependent unsent projections too; never discard uncertain writes.
        final related = queue.where((q) => q.id == a.id).toList();
        if (related.any((q) => !canDiscard(q))) return;
        queue.removeWhere((q) => q.id == a.id);
        try {
          await _persist();
        } catch (_) {
          queue.addAll(related);
          _storageFailed = true;
          rethrow;
        }
      });
}
