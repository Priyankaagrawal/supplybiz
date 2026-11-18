// T-077 / US-081: server-owned impact and state; encrypted explicit retry.
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
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionDate;

final availabilityProvider =
    ChangeNotifierProvider.autoDispose<AvailabilityController>((ref) {
  final identity = ref.watch(sessionProvider
          .select((s) => (s.user?.id, s.user?.activeRole?.value))),
      config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  return AvailabilityController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:vendor-availability');
});

class AvailabilityController extends ChangeNotifier {
  AvailabilityController(this.client, this.store, this.owner)
      : api = VendorAvailabilityApi(client.dio);
  final NetworkClient client;
  final OnboardingDrafts store;
  final String owner;
  final VendorAvailabilityApi api;
  AvailabilityResponse? state;
  List<HolidayRecord> holidays = [];
  Map<String, dynamic>? pending;
  AppFailure? failure;
  int? cancelledOrders;
  bool completed = false,
      busy = false,
      stale = false,
      _disposed = false,
      _restored = false;
  int shown = 20;
  bool get canWrite =>
      state != null && !busy && !stale && pending == null && !_disposed;
  bool get canReduce => canWrite && state!.canReduceActivity;
  bool get canResume => canWrite && state!.canResume;
  List<HolidayRecord> get visible => holidays.take(shown).toList();
  void more() {
    shown += 20;
    notifyListeners();
  }

  bool future(HolidayRecord h) =>
      state != null &&
      subscriptionDate(h.date)
              .compareTo(subscriptionDate(state!.businessDate)) >
          0;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _persist(Map<String, dynamic>? request) async {
    if (_disposed) return;
    await store.write(owner, {
      'holidays': jsonEncode(holidays.map((h) => h.toJson()).toList()),
      if (state != null) 'state': jsonEncode(state!.toJson()),
      if (request != null) 'pending': jsonEncode(request)
    });
  }

  Future<void> _run(Future<void> Function() f) async {
    if (busy || _disposed) return;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await f();
    } catch (e) {
      if (_disposed) return;
      failure = e is DioException
          ? mapDioFailure(e)
          : e is AppFailure
              ? e
              : const UnknownFailure();
      stale = true;
      if (failure is UnauthorizedFailure ||
          failure is ForbiddenFailure &&
              failure!.code != 'PLAN_FEATURE_LOCKED') {
        state = null;
        holidays = [];
        pending = null;
        cancelledOrders = null;
        completed = false;
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
          if (saved['state'] != null) {
            state = AvailabilityResponse.fromJson(
                Map<String, dynamic>.from(jsonDecode(saved['state']!) as Map));
          }
          holidays = (jsonDecode(saved['holidays'] ?? '[]') as List)
              .map((h) =>
                  HolidayRecord.fromJson(Map<String, dynamic>.from(h as Map)))
              .toList();
          pending = saved['pending'] == null
              ? null
              : Map<String, dynamic>.from(jsonDecode(saved['pending']!) as Map);
          stale = state != null;
          _restored = true;
          notifyListeners();
        }
        await _refresh();
      });
  Future<void> _refresh() async {
    final current = (await api.availabilityControllerGet()).data!,
        rows = <HolidayRecord>[];
    for (var offset = 0;;) {
      final page =
          (await api.availabilityControllerList(limit: 50, offset: offset))
              .data!;
      if (_disposed) return;
      rows.addAll(page.items);
      offset += page.items.length;
      if (offset >= page.total) break;
      if (page.items.isEmpty) {
        throw const ServerFailure(code: 'HOLIDAYS_CHANGED');
      }
    }
    if (_disposed) return;
    state = current;
    holidays = rows;
    await _persist(pending);
    if (_disposed) return;
    stale = false;
  }

  Future<DeliveryImpact?> impact({String? date}) async {
    if (!canWrite) return null;
    DeliveryImpact? result;
    await _run(() async {
      result = date == null
          ? (await api.availabilityControllerPauseImpact()).data!
          : (await api.availabilityControllerImpact(date: date)).data!;
    });
    return _disposed ? null : result;
  }

  Future<void> submit(String action, Map<String, dynamic> body,
      {String? id}) async {
    if (!canWrite) return;
    await _run(() async {
      completed = false;
      cancelledOrders = null;
      pending = {
        'action': action,
        'body': jsonDecode(jsonEncode(body)),
        'id': id,
        'key': const Uuid().v4()
      };
      await _send();
    });
  }

  Future<void> retry() => _run(_send);
  Future<void> _send() async {
    final p = pending;
    if (p == null || _disposed) return;
    await _persist(p);
    if (_disposed) return;
    final key = p['key'] as String,
        body = Map<String, dynamic>.from(p['body'] as Map);
    int? count;
    try {
      switch (p['action']) {
        case 'PATCH':
          count = (await api.availabilityControllerPatch(
                  idempotencyKey: key,
                  availabilityPatch: AvailabilityPatch.fromJson(body)))
              .data!
              .cancelledOrders;
        case 'HOLIDAY':
          count = (await api.availabilityControllerCreate(
                  idempotencyKey: key,
                  holidayInput: HolidayInput.fromJson(body)))
              .data!
              .cancelledOrders;
        case 'DELETE':
          await api.availabilityControllerDelete(
              idempotencyKey: key, id: p['id'] as String);
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
    cancelledOrders = count;
    completed = true;
    stale = true;
    await _refresh();
  }
}
