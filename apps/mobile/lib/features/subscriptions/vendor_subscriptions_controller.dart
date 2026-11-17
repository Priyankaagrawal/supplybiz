// T-076 / US-070–073: owned generated APIs, encrypted snapshots and explicit retry.
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

final vendorSubscriptionsProvider =
    ChangeNotifierProvider.autoDispose<VendorSubscriptionsController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  final model = VendorSubscriptionsController(
      client,
      ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:vendor-subscriptions');
  if (identity.$1 != null && identity.$2 == 'VENDOR') {
    Future.microtask(model.load);
  }
  return model;
});

String subscriptionDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
DateTime? subscriptionParseDate(String text) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
  final day = DateTime.tryParse('${text}T00:00:00Z');
  return day != null && subscriptionDate(day) == text ? day : null;
}

/// RULE-16: exact paise, clipped selected calendar month; display estimate only.
({BigInt daily, BigInt monthly}) subscriptionEstimate(BigInt rate, int qty,
    Set<int> days, DateTime start, DateTime? end, DateTime month) {
  var count = 0;
  for (var d = DateTime.utc(month.year, month.month);
      d.month == month.month;
      d = d.add(const Duration(days: 1))) {
    if (!d.isBefore(start) &&
        (end == null || !d.isAfter(end)) &&
        days.contains(d.weekday)) {
      count++;
    }
  }
  return (
    daily: rate * BigInt.from(qty),
    monthly: rate * BigInt.from(qty) * BigInt.from(count)
  );
}

class VendorSubscriptionsController extends ChangeNotifier {
  VendorSubscriptionsController(this.client, this.store, this.owner)
      : api = VendorSubscriptionsApi(client.dio),
        settingsApi = VendorSubscriptionSettingsApi(client.dio) {
    // The generated Dart date serializer emits midnight timestamps. The public
    // contract requires calendar dates; normalize only these owned POST fields.
    client.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      final path = options.uri.path;
      final fields = options.method == 'POST' &&
              path == '/api/v1/vendor/subscriptions'
          ? ['startDate', 'endDate']
          : options.method == 'POST' &&
                  RegExp(r'^/api/v1/vendor/subscriptions/[0-9a-f-]{36}/pause$')
                      .hasMatch(path)
              ? ['fromDate', 'toDate']
              : options.method == 'POST' &&
                      RegExp(r'^/api/v1/vendor/subscriptions/[0-9a-f-]{36}/skip$')
                          .hasMatch(path)
                  ? ['date']
                  : <String>[];
      if (fields.isNotEmpty) {
        final raw = options.data;
        final body = Map<String, dynamic>.from(
            raw is String ? jsonDecode(raw) as Map : raw as Map);
        for (final field in fields) {
          final value = body[field];
          if (value is String &&
              RegExp(r'^\d{4}-\d{2}-\d{2}T00:00:00(?:\.0+)?Z?$')
                  .hasMatch(value)) {
            body[field] = value.substring(0, 10);
          }
        }
        options.data = raw is String ? jsonEncode(body) : body;
      }
      handler.next(options);
    }));
  }
  final NetworkClient client;
  final OnboardingDrafts store;
  final String owner;
  final VendorSubscriptionsApi api;
  final VendorSubscriptionSettingsApi settingsApi;
  List<SubscriptionRecord> rows = [];
  List<CustomerResponse> customers = [];
  List<ProductResponse> products = [];
  List<String> slots = [];
  SubscriptionSettingsResponse? settings;
  SubscriptionMutation? result;
  Map<String, dynamic>? pending;
  AppFailure? failure;
  bool busy = false, cached = false, ready = false, _disposed = false;
  String search = '', filter = 'ALL';
  int shown = 20;
  bool get canWrite =>
      !_disposed && ready && !cached && !busy && pending == null;
  bool get canEdit => canWrite && settings?.canEditSubscriptions == true;
  bool get canReduce => canWrite && settings?.canReduceActivity == true;
  bool get retryExpired =>
      pending?['action'] == 'SETTINGS' &&
      DateTime.now()
              .toUtc()
              .difference(DateTime.parse(pending!['savedAt'] as String)) >=
          const Duration(hours: 23);
  DateTime? get tomorrow => settings?.businessDate.add(const Duration(days: 1));
  List<SubscriptionRecord> get filtered => rows
      .where((r) =>
          (filter == 'ALL' || r.status == filter) &&
          ('${r.productName} ${customerName(r.vendorCustomerId)}'
              .toLowerCase()
              .contains(search.toLowerCase())))
      .toList();
  List<SubscriptionRecord> get visible => filtered.take(shown).toList();
  String customerName(String id) =>
      customers.where((c) => c.id == id).firstOrNull?.name ?? '';
  SubscriptionRecord? find(String id) =>
      rows.where((r) => r.id == id).firstOrNull;
  void query(String value, String status) {
    search = value;
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
    _disposed = true;
    super.dispose();
  }

  Map<String, String> snapshot({Map<String, dynamic>? request}) => {
        if (settings != null) 'settings': jsonEncode(settings!.toJson()),
        'rows': jsonEncode(rows.map((r) => r.toJson()).toList()),
        'customers': jsonEncode(customers.map((r) => r.toJson()).toList()),
        'products': jsonEncode(products.map((r) => r.toJson()).toList()),
        'slots': jsonEncode(slots),
        if (request != null) 'pending': jsonEncode(request),
      };
  Future<void> _persist(Map<String, dynamic>? request) async {
    if (!_disposed) await store.write(owner, snapshot(request: request));
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
      cached = ready;
      if (failure is UnauthorizedFailure ||
          failure is ForbiddenFailure &&
              failure?.code != 'PLAN_FEATURE_LOCKED') {
        rows = [];
        customers = [];
        products = [];
        slots = [];
        settings = null;
        pending = null;
        ready = false;
        cached = false;
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

  Future<void> load() => _run(() async {
        if (!ready) {
          final saved = await store.read(owner);
          if (_disposed) return;
          if (saved['settings'] != null) {
            settings = SubscriptionSettingsResponse.fromJson(
                Map<String, dynamic>.from(
                    jsonDecode(saved['settings']!) as Map));
            rows = (jsonDecode(saved['rows'] ?? '[]') as List)
                .map((v) => SubscriptionRecord.fromJson(
                    Map<String, dynamic>.from(v as Map)))
                .toList();
            customers = (jsonDecode(saved['customers'] ?? '[]') as List)
                .map((v) => CustomerResponse.fromJson(
                    Map<String, dynamic>.from(v as Map)))
                .toList();
            products = (jsonDecode(saved['products'] ?? '[]') as List)
                .map((v) => ProductResponse.fromJson(
                    Map<String, dynamic>.from(v as Map)))
                .toList();
            slots = (jsonDecode(saved['slots'] ?? '[]') as List).cast<String>();
            ready = true;
            cached = true;
          }
          if (saved['pending'] != null) {
            pending =
                Map<String, dynamic>.from(jsonDecode(saved['pending']!) as Map);
          }
          notifyListeners();
        }
        await _refresh();
      });
  Future<void> _refresh() async {
    final controls =
        (await settingsApi.subscriptionSettingsControllerGet()).data!;
    final list = <SubscriptionRecord>[];
    for (var offset = 0;;) {
      final page = (await api.vendorSubscriptionsControllerList(
              limit: 50, offset: offset))
          .data!;
      if (_disposed) return;
      list.addAll(page.items);
      offset += page.items.length;
      if (offset >= page.total) break;
      if (page.items.isEmpty) {
        throw const ServerFailure(code: 'SUBSCRIPTIONS_CHANGED');
      }
    }
    final people = <CustomerResponse>[];
    for (var offset = 0;;) {
      final page = (await VendorCustomersApi(client.dio)
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
    final catalog = <ProductResponse>[];
    for (var offset = 0;;) {
      final page = (await CatalogApi(client.dio)
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
    final profile =
        (await VendorOnboardingApi(client.dio).vendorsControllerProfile())
            .data!;
    if (_disposed) return;
    rows = list;
    customers = people;
    products = catalog;
    slots = profile.settings.timeSlots;
    settings = controls;
    await _persist(pending);
    if (_disposed) return;
    ready = true;
    cached = false;
  }

  Future<void> submit(String action, Map<String, dynamic> body,
      {String? id}) async {
    if (!canWrite) return;
    await _run(() async {
      result = null;
      pending = {
        'action': action,
        'body': jsonDecode(jsonEncode(body)),
        'id': id,
        'key': const Uuid().v4(),
        'savedAt': DateTime.now().toUtc().toIso8601String()
      };
      await _send();
    });
  }

  Future<void> retry() => _run(_send);

  /// Expired settings retries require reloading/reviewing the latest version, never a new key automatically.
  Future<void> discardExpired() => _run(() async {
        if (!retryExpired) return;
        await _persist(null);
        if (_disposed) return;
        pending = null;
        cached = true;
        await _refresh();
      });
  Future<void> _send() async {
    final p = pending;
    if (p == null || _disposed) return;
    if (retryExpired) {
      throw const ConflictFailure(code: 'SETTINGS_RETRY_EXPIRED');
    }
    await _persist(p);
    if (_disposed) return;
    final body = Map<String, dynamic>.from(p['body'] as Map),
        id = p['id'] as String?,
        key = p['key'] as String;
    SubscriptionMutation? acknowledgement;
    try {
      switch (p['action']) {
        case 'CREATE':
          acknowledgement = (await api.vendorSubscriptionsControllerCreate(
                  idempotencyKey: key,
                  vendorSubscriptionInput:
                      VendorSubscriptionInput.fromJson(body)))
              .data!;
        case 'EDIT':
          acknowledgement = (await api.vendorSubscriptionsControllerEdit(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionPatch: SubscriptionPatch.fromJson(body)))
              .data!;
        case 'PAUSE':
          acknowledgement = (await api.vendorSubscriptionsControllerPause(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionPause: SubscriptionPause.fromJson(body)))
              .data!;
        case 'SKIP':
          acknowledgement = (await api.vendorSubscriptionsControllerSkip(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionSkip: SubscriptionSkip.fromJson(body)))
              .data!;
        case 'CANCEL':
          acknowledgement = (await api.vendorSubscriptionsControllerCancel(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionVersion: SubscriptionVersion.fromJson(body)))
              .data!;
        case 'RESUME':
          acknowledgement = (await api.vendorSubscriptionsControllerResume(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionVersion: SubscriptionVersion.fromJson(body)))
              .data!;
        case 'APPROVE':
          acknowledgement = (await api.vendorSubscriptionsControllerApprove(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionVersion: SubscriptionVersion.fromJson(body)))
              .data!;
        case 'REJECT':
          acknowledgement = (await api.vendorSubscriptionsControllerReject(
                  id: id!,
                  idempotencyKey: key,
                  subscriptionReject: SubscriptionReject.fromJson(body)))
              .data!;
        case 'SETTINGS':
          await settingsApi.subscriptionSettingsControllerPatch(
              idempotencyKey: key,
              subscriptionSettingsPatch:
                  SubscriptionSettingsPatch.fromJson(body));
        default:
          throw const UnknownFailure(code: 'INVALID_SAVED_REQUEST');
      }
    } catch (error) {
      final f = error is DioException ? mapDioFailure(error) : error;
      if (f is ValidationFailure ||
          f is ConflictFailure ||
          f is ForbiddenFailure && f.code == 'PLAN_FEATURE_LOCKED' ||
          f is BusinessRuleFailure && f.code != 'RATE_LIMITED' ||
          f is NotFoundFailure) {
        await _persist(null);
        if (!_disposed) {
          pending = null;
          cached = true;
        }
      }
      rethrow;
    }
    if (_disposed) return;
    // Keep the exact request if the local acknowledgement write fails after a server commit.
    await _persist(null);
    if (_disposed) return;
    pending = null;
    result = acknowledgement;
    cached = true;
    await _refresh();
  }
}
