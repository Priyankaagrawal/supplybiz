// T-078: accepted-link APIs, account-scoped encrypted replay and server dates.
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
import 'vendor_subscriptions_controller.dart' show subscriptionDate;

final customerSubscriptionsProvider =
    ChangeNotifierProvider.autoDispose<CustomerSubscriptionsController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  return CustomerSubscriptionsController(
      client,
      ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:customer-subscriptions');
});

class CustomerSubscriptionsController extends ChangeNotifier {
  CustomerSubscriptionsController(this.client, this.store, this.owner)
      : api = CustomerSubscriptionsApi(client.dio) {
    // Normalize only generated subscription calendar-date mutation fields.
    client.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (o.method == 'POST' &&
          RegExp(r'^/api/v1/customer/subscriptions(?:/[0-9a-f-]{36}/(?:pause|skip))?$')
              .hasMatch(o.uri.path)) {
        final raw = o.data;
        final body = Map<String, dynamic>.from(
            raw is String ? jsonDecode(raw) as Map : raw as Map);
        for (final field in [
          'startDate',
          'endDate',
          'fromDate',
          'toDate',
          'date'
        ]) {
          final value = body[field];
          if (value is String &&
              RegExp(r'^\d{4}-\d{2}-\d{2}T00:00:00(?:\.0+)?Z?$')
                  .hasMatch(value)) {
            body[field] = value.substring(0, 10);
          }
        }
        o.data = raw is String ? jsonEncode(body) : body;
      }
      h.next(o);
    }));
  }
  final NetworkClient client;
  final OnboardingDrafts store;
  final String owner;
  final CustomerSubscriptionsApi api;
  List<SubscriptionRecord> rows = [];
  List<AddressResponse> addresses = [];
  SubscriptionPlans? plans;
  CustomerSettlementOptions? settlement;
  SubscriptionStatement? statement;
  SubscriptionMutation? result;
  Map<String, dynamic>? pending;
  AppFailure? failure;
  DateTime? businessDate;
  String? selectedId, vendorId, addressId;
  bool busy = false,
      stale = false,
      ready = false,
      _disposed = false,
      _restored = false;
  int shown = 20;
  bool get canWrite =>
      ready && !busy && !stale && pending == null && !_disposed;
  bool get canCreate => canWrite && plans != null && addressId != null;
  bool get upiAvailable => settlement?.upiId != null;
  SubscriptionRecord? find(String id) =>
      rows.where((r) => r.id == id).firstOrNull;
  List<SubscriptionRecord> get visible => rows.take(shown).toList();
  void more() {
    shown += 20;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _persist(Map<String, dynamic>? request) async {
    if (!_disposed) {
      await store.write(owner, {
        'rows': jsonEncode(rows.map((r) => r.toJson()).toList()),
        if (businessDate != null) 'day': subscriptionDate(businessDate!),
        if (request != null) 'pending': jsonEncode(request),
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_disposed || busy) return;
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
      stale = true;
      if (failure is NotFoundFailure && selectedId != null) {
        rows.removeWhere((r) => r.id == selectedId);
        statement = null;
      }
      if (failure is UnauthorizedFailure ||
          failure is ForbiddenFailure &&
              failure!.code != 'PLAN_FEATURE_LOCKED') {
        rows = [];
        addresses = [];
        plans = null;
        settlement = null;
        statement = null;
        pending = null;
        ready = false;
        result = null;
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

  Future<void> load({String? id}) => _run(() async {
        if (selectedId != id) {
          selectedId = id;
          statement = null;
        }
        if (!_restored) {
          final saved = await store.read(owner);
          if (_disposed) return;
          rows = (jsonDecode(saved['rows'] ?? '[]') as List)
              .map((r) => SubscriptionRecord.fromJson(
                  Map<String, dynamic>.from(r as Map)))
              .toList();
          businessDate =
              saved['day'] == null ? null : DateTime.parse(saved['day']!);
          pending = saved['pending'] == null
              ? null
              : Map<String, dynamic>.from(jsonDecode(saved['pending']!) as Map);
          ready = businessDate != null;
          stale = ready;
          _restored = true;
          notifyListeners();
        }
        await _refresh();
      });
  Future<void> _refresh() async {
    final list = <SubscriptionRecord>[];
    DateTime? day;
    for (var offset = 0;;) {
      final page = (await api.customerSubscriptionsControllerList(
              limit: 50, offset: offset))
          .data!;
      if (_disposed) return;
      day = page.businessDate;
      list.addAll(page.items);
      offset += page.items.length;
      if (offset >= page.total) break;
      if (page.items.isEmpty) {
        throw const ServerFailure(code: 'SUBSCRIPTIONS_CHANGED');
      }
    }
    if (selectedId != null) {
      final detail =
          (await api.customerSubscriptionsControllerGet(id: selectedId!)).data!;
      list.removeWhere((r) => r.id == detail.id);
      list.insert(0, detail);
    }
    if (_disposed) return;
    rows = list;
    businessDate = day;
    statement = null;
    await _persist(pending);
    if (_disposed) return;
    ready = true;
    stale = false;
  }

  Future<void> prepare(String vendor, {String? address}) => _run(() async {
        vendorId = vendor;
        plans = null;
        settlement = null;
        final list =
            (await CustomerAddressesApi(client.dio).addressesControllerList())
                .data!
                .items;
        if (_disposed) return;
        addresses = list;
        addressId = address ??
            (list.any((a) => a.id == addressId)
                ? addressId
                : list.where((a) => a.isDefault).firstOrNull?.id ??
                    list.firstOrNull?.id);
        if (addressId != null) {
          plans = (await api.subscriptionPlansControllerPlans(
                  id: vendor, addressId: addressId!))
              .data!;
          // An unlinked new customer may create a subscription, but has no settlement account yet.
          try {
            settlement = (await CustomerKhataApi(client.dio)
                    .customerKhataControllerOptions(id: vendor))
                .data!;
          } on DioException catch (e) {
            if (e.response?.statusCode != 404) rethrow;
          }
        }
        if (_disposed) return;
        stale = false;
      });
  Future<void> readStatement(String id, String month, {bool more = false}) =>
      _run(() async {
        final old =
            more && statement?.subscriptionId == id && statement?.month == month
                ? statement
                : null;
        final page = (await api.customerSubscriptionsControllerStatement(
                id: id,
                month: month,
                limit: 50,
                offset: old?.items.length ?? 0))
            .data!;
        if (_disposed) return;
        statement = old == null
            ? page
            : SubscriptionStatement(
                subscriptionId: page.subscriptionId,
                month: page.month,
                items: [...old.items, ...page.items],
                total: page.total,
                deliveredAmountPaise: page.deliveredAmountPaise,
                deliveredQty: page.deliveredQty,
                ledger: page.ledger);
      });
  Future<void> submit(String action, Map<String, dynamic> body, {String? id}) =>
      _run(() async {
        if (!ready ||
            stale ||
            pending != null ||
            action == 'CREATE' && plans == null) {
          return;
        }
        result = null;
        pending = {
          'action': action,
          'body': jsonDecode(jsonEncode(body)),
          'id': id,
          'key': const Uuid().v4()
        };
        await _send();
      });
  Future<void> retry() => _run(_send);
  Future<void> _send() async {
    final p = pending;
    if (p == null || _disposed) return;
    await _persist(
        p); // Never send a mutation that cannot first be recovered locally.
    if (_disposed) return;
    final key = p['key'] as String,
        id = p['id'] as String?,
        body = Map<String, dynamic>.from(p['body'] as Map);
    SubscriptionMutation ack;
    try {
      switch (p['action']) {
        case 'CREATE':
          ack = (await api.customerSubscriptionsControllerCreate(
                  idempotencyKey: key,
                  customerSubscriptionInput:
                      CustomerSubscriptionInput.fromJson(body)))
              .data!;
        case 'EDIT':
          ack = (await api.customerSubscriptionsControllerEdit(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionPatch: SubscriptionPatch.fromJson(body)))
              .data!;
        case 'PAUSE':
          ack = (await api.customerSubscriptionsControllerPause(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionPause: SubscriptionPause.fromJson(body)))
              .data!;
        case 'RESUME':
          ack = (await api.customerSubscriptionsControllerResume(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionVersion: SubscriptionVersion.fromJson(body)))
              .data!;
        case 'SKIP':
          ack = (await api.customerSubscriptionsControllerSkip(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionSkip: SubscriptionSkip.fromJson(body)))
              .data!;
        case 'CANCEL':
          ack = (await api.customerSubscriptionsControllerCancel(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionVersion: SubscriptionVersion.fromJson(body)))
              .data!;
        default:
          throw const UnknownFailure(code: 'INVALID_SAVED_REQUEST');
      }
    } catch (e) {
      final f = e is DioException ? mapDioFailure(e) : e;
      if (f is ValidationFailure ||
          f is ConflictFailure ||
          f is NotFoundFailure ||
          f is ForbiddenFailure && f.code == 'PLAN_FEATURE_LOCKED' ||
          f is BusinessRuleFailure && f.code != 'RATE_LIMITED') {
        await _persist(null);
        if (!_disposed) {
          pending = null;
          stale = true;
        }
      }
      rethrow;
    }
    if (_disposed) return;
    await _persist(null);
    if (_disposed) return;
    pending = null;
    result = ack;
    stale = true;
    await _refresh();
  }
}
