// T-029 / US-060–US-062: owned customers, encrypted snapshot and explicit retry.
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

final customersProvider =
    ChangeNotifierProvider.autoDispose<CustomersController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  final model = CustomersController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:customers');
  ref.onDispose(client.close);
  if (identity.$1 != null && identity.$2 == 'VENDOR') {
    Future.microtask(model.load);
  }
  return model;
});

class CustomersController extends ChangeNotifier {
  CustomersController(this.client, this.store, this.owner)
      : api = VendorCustomersApi(client.dio);
  final NetworkClient client;
  final VendorCustomersApi api;
  final OnboardingDrafts store;
  final String owner;
  List<CustomerResponse> customers = [];
  Set<String> subscriptions = {};
  int? customerLimit;
  int shown = 20;
  String search = '', filter = 'ALL';
  bool busy = false, ready = false, cached = false, _disposed = false;
  AppFailure? failure;
  Map<String, dynamic>? pending;
  bool get canEdit =>
      !_disposed && ready && !busy && !cached && pending == null;
  int get activeCount =>
      customers.where((c) => c.status.value == 'ACTIVE').length;
  List<CustomerResponse> get filtered => customers
      .where((c) =>
          (c.name.toLowerCase().contains(search.toLowerCase()) ||
              c.mobile.contains(search)) &&
          (filter == 'ALL' ||
              (filter == 'SUBSCRIPTION'
                  ? subscriptions.contains(c.id)
                  : c.status.value == filter)))
      .toList();
  List<CustomerResponse> get visible => filtered.take(shown).toList();
  CustomerResponse? find(String id) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  void query(String text, String status) {
    search = text;
    filter = status;
    shown = 20;
    if (!_disposed) notifyListeners();
  }

  void more() {
    shown += 20;
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
          required List<CustomerResponse> rows}) =>
      store.write(owner, {
        'customers': jsonEncode(rows.map((c) => c.toJson()).toList()),
        'subscriptions': jsonEncode(subscriptions.toList()),
        if (customerLimit != null) 'limit': '$customerLimit',
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
        cached = ready;
      }
      if (failure is ForbiddenFailure || failure is UnauthorizedFailure) {
        customers = [];
        subscriptions = {};
        customerLimit = null;
        ready = false;
        cached = false;
        pending = null;
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
        if (!ready) {
          final saved = await store.read(owner);
          if (_disposed) return;
          customers = (jsonDecode(saved['customers'] ?? '[]') as List)
              .map((v) => CustomerResponse.fromJson(
                  Map<String, dynamic>.from(v as Map)))
              .toList();
          subscriptions = (jsonDecode(saved['subscriptions'] ?? '[]') as List)
              .cast<String>()
              .toSet();
          customerLimit = int.tryParse(saved['limit'] ?? '');
          pending = saved['pending'] == null
              ? null
              : Map<String, dynamic>.from(jsonDecode(saved['pending']!) as Map);
          ready = saved.containsKey('customers');
          cached = ready;
          notifyListeners();
        }
        // Fetch full snapshots before replacing cache: offline filters must never imply
        // a complete result while silently searching only the first API page.
        final rows = <String, CustomerResponse>{}, subscribed = <String>{};
        for (final status in ['ALL', 'SUBSCRIPTION']) {
          var offset = 0;
          while (true) {
            final page = (await api.customersControllerList(
                    filter: status, limit: 100, offset: offset))
                .data!;
            if (_disposed) return;
            for (final row in page.items) {
              if (status == 'ALL') {
                rows[row.id] = row;
              } else {
                subscribed.add(row.id);
              }
            }
            if (status == 'ALL') customerLimit = page.customerLimit;
            offset += page.items.length;
            if (offset >= page.total) break;
            if (page.items.isEmpty) {
              throw const ServerFailure(code: 'CUSTOMERS_CHANGED');
            }
          }
        }
        if (_disposed) return;
        subscriptions = subscribed;
        await _persist(request: pending, rows: rows.values.toList());
        if (_disposed) return;
        customers = rows.values.toList();
        ready = true;
        cached = false;
      });
  Future<void> save(Map<String, dynamic> fields, {String? id}) =>
      _run(() async {
        if (!canWriteWhileBusy) throw const NetworkFailure();
        pending = {'id': id, 'body': fields, 'key': const Uuid().v4()};
        await _sendPending();
      });
  // _run owns the busy flag; callers still use canEdit before entering it.
  bool get canWriteWhileBusy => ready && !cached && pending == null;
  Future<void> retryPending() => _run(_sendPending);
  Future<void> _sendPending() async {
    final request = pending;
    if (request == null || _disposed) return;
    await _persist(request: request, rows: customers);
    if (_disposed) return;
    final body = Map<String, dynamic>.from(request['body'] as Map),
        id = request['id'] as String?,
        key = request['key'] as String;
    CustomerResponse result;
    try {
      if (id == null) {
        result = (await api.customersControllerCreate(
                idempotencyKey: key,
                customerInput: CustomerInput.fromJson(body)))
            .data!;
      } else {
        // Generated PATCH omits nulls. Preserve explicit email clearing through the
        // same authorized/idempotent transport and decode the generated response.
        final response = await client.request<Map<String, dynamic>>(
            '/api/v1/vendor/customers/$id',
            data: body,
            options:
                Options(method: 'PATCH', headers: {'Idempotency-Key': key}));
        result = CustomerResponse.fromJson(response.data!);
      }
    } catch (error) {
      final f = error is DioException ? mapDioFailure(error) : error;
      if (f is ValidationFailure ||
          f is ConflictFailure ||
          f is NotFoundFailure ||
          f is BusinessRuleFailure) {
        await _persist(rows: customers);
        pending = null;
      }
      rethrow;
    }
    if (_disposed) return;
    final next = [result, ...customers.where((c) => c.id != result.id)];
    await _persist(rows: next);
    if (_disposed) return;
    customers = next;
    pending = null;
    cached = false;
  }
}
