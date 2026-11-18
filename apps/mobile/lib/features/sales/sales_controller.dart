// T-080: same native lease/snapshot/worker safeguards as T-050. No local ledger.
import 'dart:async';
import 'dart:convert';
import 'package:device_coordination/device_coordination.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import '../../core/network/app_failure.dart';
import '../auth/session_controller.dart';
import '../home/home_controller.dart';
import '../onboarding/onboarding_controller.dart';
import '../deliveries/delivery_background.dart';

final salesProvider = ChangeNotifierProvider<SalesController>((ref) {
  final identity = ref.watch(sessionProvider
          .select((s) => (s.user?.id, s.user?.activeRole?.value))),
      client = homeClient(ref);
  ref.onDispose(client.close);
  return SalesController(client.dio, ref.read(onboardingDraftsProvider),
      '${ref.read(authConfigProvider).baseUrl}:${identity.$1}:sales',
      coordinated: true, schedule: scheduleDeliverySync);
});
final saleMax = BigInt.parse('9223372036854775807');
BigInt? saleRupees(String text) {
  if (text.length > 20) return null;
  if (!RegExp(r'^(0|[1-9]\d*)(?:\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.'),
      amount = BigInt.parse(parts[0]) * BigInt.from(100) +
          BigInt.parse((parts.length == 1 ? '' : parts[1]).padRight(2, '0'));
  return amount <= saleMax ? amount : null;
}

String saleDecimal(BigInt paise) =>
    '${paise ~/ BigInt.from(100)}.${(paise % BigInt.from(100)).toString().padLeft(2, '0')}';

class SaleAction {
  SaleAction(this.key, this.body,
      {this.state = 'PENDING', this.attempts = 0, this.nextAt, this.code});
  final String key;
  final Map<String, dynamic> body;
  String state;
  int attempts;
  DateTime? nextAt;
  String? code;
  bool get rejected => state == 'REJECTED';
  bool get retryable => state == 'RETRYABLE';
  Map<String, dynamic> toJson() => {
        'key': key,
        'body': body,
        'state': state,
        'attempts': attempts,
        'nextAt': nextAt?.toIso8601String(),
        'code': code
      };
  factory SaleAction.fromJson(Map<String, dynamic> j) => SaleAction(
      j['key'] as String, Map<String, dynamic>.from(j['body'] as Map),
      state: j['state'] == 'SENDING' ? 'PENDING' : j['state'] as String,
      attempts: j['attempts'] as int,
      nextAt: DateTime.tryParse(j['nextAt'] as String? ?? ''),
      code: j['code'] as String?);
}

class SalesController extends ChangeNotifier {
  SalesController(this.dio, this.store, this.owner,
      {this.coordinated = false, this.schedule});
  final Dio dio;
  final OnboardingDrafts store;
  final String owner;
  final bool coordinated;
  final Future<void> Function()? schedule;
  List<ProductResponse> products = [];
  List<CustomerResponse> customers = [];
  final queue = <SaleAction>[];
  final receipts = <String, SaleResponse>{};
  final acknowledged = <String>{};
  bool busy = false,
      stale = true,
      restored = false,
      _disposed = false,
      _storageFailed = false,
      _recoveryScheduled = false;
  String? _savedSnapshot;
  AppFailure? failure;
  Future<void> _tail = Future.value();
  bool get canCreate =>
      restored && !busy && !_disposed && !_storageFailed && products.isNotEmpty;
  int available(String id) {
    final base = products.where((p) => p.id == id).firstOrNull?.stockQty ?? 0;
    final reserved = queue.where((a) => !a.rejected).fold<int>(
        0,
        (sum, a) =>
            sum +
            (a.body['items'] as List)
                .where((i) => i['productId'] == id)
                .fold<int>(0, (n, i) => n + (i['qty'] as int)));
    return base - reserved < 0 ? 0 : base - reserved;
  }

  SaleResponse? receipt(String key) => receipts[key];
  bool saved(String key) =>
      acknowledged.contains(key) || queue.any((a) => a.key == key);
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
      'products': products.map((p) => p.toJson()).toList(),
      'customers': customers.map((p) => p.toJson()).toList(),
      'queue': queue.map((a) => a.toJson()).toList(),
      'receipts': receipts.map((key, value) => MapEntry(key, value.toJson())),
      'acknowledged': acknowledged.toList()
    });
    await store.write(owner, {'snapshot': snapshot});
    _savedSnapshot = snapshot;
  }

  Future<void> _restore() async {
    final saved = await store.read(owner);
    if (_disposed) return;
    if (restored && !_storageFailed && saved['snapshot'] == _savedSnapshot) {
      return;
    }
    products = [];
    customers = [];
    queue.clear();
    receipts.clear();
    acknowledged.clear();
    _savedSnapshot = saved['snapshot'];
    if (saved['snapshot'] != null) {
      final j = jsonDecode(saved['snapshot']!) as Map;
      products = (j['products'] as List)
          .map((p) =>
              ProductResponse.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      customers = (j['customers'] as List)
          .map((p) =>
              CustomerResponse.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      queue.addAll((j['queue'] as List).map(
          (a) => SaleAction.fromJson(Map<String, dynamic>.from(a as Map))));
      receipts.addAll((j['receipts'] as Map).map((key, value) => MapEntry(
          key as String,
          SaleResponse.fromJson(Map<String, dynamic>.from(value as Map)))));
      acknowledged.addAll((j['acknowledged'] as List).cast<String>());
    }
    restored = true;
    stale = true;
    _storageFailed = false;
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
          products = [];
          customers = [];
          receipts.clear();
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

  Future<void> load() => _run(() async {
        await _flush();
        if (!_disposed && !queue.any((a) => !a.rejected)) await _fetch();
      });
  Future<void> _fetch() async {
    final catalog = <ProductResponse>[], people = <CustomerResponse>[];
    for (var offset = 0;;) {
      final page = (await CatalogApi(dio)
              .catalogControllerList(limit: 50, offset: offset))
          .data!;
      if (_disposed) return;
      catalog.addAll(page.items);
      offset += page.items.length;
      if (offset >= page.total) break;
      if (page.items.isEmpty) {
        throw const ServerFailure(code: 'CATALOG_CHANGED');
      }
    }
    for (var offset = 0;;) {
      final page = (await VendorCustomersApi(dio)
              .customersControllerList(limit: 100, offset: offset))
          .data!;
      if (_disposed) return;
      people.addAll(page.items);
      offset += page.items.length;
      if (offset >= page.total) break;
      if (page.items.isEmpty) {
        throw const ServerFailure(code: 'CUSTOMERS_CHANGED');
      }
    }
    if (_disposed) return;
    products = catalog;
    customers = people;
    stale = false;
    await _persist();
  }

  Future<bool> enqueue(String key, List<Map<String, dynamic>> items,
      {String? customerId,
      required String paidPaise,
      required String method}) async {
    var stored = false;
    await _run(() async {
      if (_storageFailed || saved(key)) {
        stored = saved(key);
        return;
      }
      final paid = BigInt.tryParse(paidPaise);
      if (items.isEmpty ||
          items.length > 100 ||
          !['CASH', 'UPI', 'OTHER'].contains(method) ||
          paid == null ||
          paid < BigInt.zero ||
          paid > saleMax) {
        throw const BusinessRuleFailure(code: 'SALE_INVALID');
      }
      if (customerId != null &&
          !customers
              .any((c) => c.id == customerId && c.status.value == 'ACTIVE')) {
        throw const BusinessRuleFailure(code: 'CUSTOMER_NOT_FOUND');
      }
      final ids = <String>{};
      var total = BigInt.zero;
      for (final item in items) {
        final id = item['productId'] as String,
            qty = item['qty'] as int,
            rate = BigInt.tryParse('${item['ratePaise']}');
        if (!ids.add(id) ||
            !products.any((p) => p.id == id && p.isActive) ||
            qty < 1 ||
            qty > 2147483647 ||
            rate == null ||
            rate < BigInt.zero ||
            rate > saleMax) {
          throw const BusinessRuleFailure(code: 'SALE_INVALID');
        }
        if (qty > available(id)) {
          throw const ConflictFailure(code: 'INSUFFICIENT_STOCK');
        }
        total += rate * BigInt.from(qty);
        if (total > saleMax) {
          throw const BusinessRuleFailure(code: 'AMOUNT_OVERFLOW');
        }
      }
      if (paid > total) {
        throw const BusinessRuleFailure(code: 'PAID_EXCEEDS_TOTAL');
      }
      if (customerId == null && paid != total) {
        throw const BusinessRuleFailure(code: 'WALKIN_MUST_BE_PAID');
      }
      final action = SaleAction(key, {
        'items': jsonDecode(jsonEncode(items)),
        'paidPaise': paidPaise,
        'paymentMethod': method,
        if (customerId != null) 'vendorCustomerId': customerId,
        'clientCreatedAt': DateTime.now().toUtc().toIso8601String()
      });
      queue.add(action);
      try {
        await schedule?.call();
        await _persist();
      } catch (_) {
        queue.remove(action);
        rethrow;
      }
      stored = true;
      if (!_disposed) await _flush();
    });
    return stored;
  }

  Future<void> flush({bool retry = false}) {
    if (restored && queue.isEmpty) return Future.value();
    return _run(() async {
      if (_storageFailed) return;
      if (retry) {
        await schedule?.call();
        for (final a in queue.where((a) => !a.rejected)) {
          a.nextAt = null;
        }
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
    for (final a in List<SaleAction>.of(queue)) {
      if (_disposed) return;
      if (a.rejected) continue;
      if (a.retryable || a.nextAt?.isAfter(DateTime.now().toUtc()) == true) {
        break;
      }
      a.state = 'SENDING';
      a.attempts++;
      try {
        await _persist();
      } catch (_) {
        _storageFailed = true;
        rethrow;
      }
      if (_disposed) return;
      SaleResponse receipt;
      try {
        receipt = (await VendorSalesApi(dio).salesControllerComplete(
                idempotencyKey: a.key,
                completeSaleInput: CompleteSaleInput.fromJson(a.body)))
            .data!;
      } on DioException catch (e) {
        if (_disposed) return;
        if ([400, 404, 409, 410, 422].contains(e.response?.statusCode)) {
          a.state = 'REJECTED';
          stale = true;
          a.code = mapDioFailure(e).code;
          await _persist();
          failure = mapDioFailure(e);
          continue;
        }
        a.state = a.attempts >= 6 ? 'RETRYABLE' : 'PENDING';
        final f = mapDioFailure(e),
            seconds = f is BusinessRuleFailure ? f.retryAfterSeconds : null;
        a.nextAt = DateTime.now()
            .toUtc()
            .add(Duration(seconds: seconds ?? (1 << a.attempts)));
        await _persist();
        rethrow;
      }
      if (_disposed) return;
      // Apply only a server-acknowledged stock delta, atomically with dequeue.
      products = products.map((p) {
        final item = (a.body['items'] as List)
            .where((i) => i['productId'] == p.id)
            .firstOrNull;
        if (item == null) return p;
        final stock = p.stockQty - (item['qty'] as int);
        return ProductResponse.fromJson(
            {...p.toJson(), 'stockQty': stock < 0 ? 0 : stock});
      }).toList();
      receipts[a.key] = receipt;
      acknowledged.add(a.key);
      queue.remove(a);
      while (receipts.length > 50) {
        receipts.remove(receipts.keys.first);
      }
      try {
        await _persist();
      } catch (_) {
        _storageFailed = true;
        rethrow;
      }
    }
  }

  bool canDiscard(SaleAction a) => a.rejected || a.attempts == 0;
  Future<void> discard(String key) => _run(() async {
        final a = queue.where((a) => a.key == key).firstOrNull;
        if (a == null || !canDiscard(a) || _storageFailed) return;
        queue.remove(a);
        try {
          await _persist();
        } catch (_) {
          queue.add(a);
          _storageFailed = true;
          rethrow;
        }
      });
}
