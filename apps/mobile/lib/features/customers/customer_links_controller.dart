// T-053 / FR-064: explicit consent; a mobile match alone grants no access.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../auth/session_controller.dart';
import '../home/home_controller.dart' show homeClient;
import '../onboarding/onboarding_controller.dart';

final customerLinksProvider =
    ChangeNotifierProvider.autoDispose<CustomerLinksController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final client = homeClient(ref);
  ref.onDispose(client.close);
  final model = CustomerLinksController(
      client,
      ref.read(onboardingDraftsProvider),
      '${ref.read(authConfigProvider).baseUrl}:${identity.$1}:customer-links');
  if (identity.$1 != null && identity.$2 == 'CUSTOMER') {
    Future.microtask(model.load);
  }
  return model;
});

class CustomerLinksController extends ChangeNotifier {
  CustomerLinksController(NetworkClient client, this.store, this.owner)
      : api = CustomerLinksApi(client.dio);
  final CustomerLinksApi api;
  final OnboardingDrafts store;
  final String owner;
  List<LinkRequestResponse> requests = [];
  Map<String, String>? pending;
  AppFailure? failure;
  int total = 0;
  bool busy = false,
      ready = false,
      stale = false,
      _disposed = false,
      _restored = false;
  String? completed;
  bool get canDecide =>
      ready && !busy && !stale && pending == null && !_disposed;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _persist() =>
      store.write(owner, {if (pending != null) 'pending': jsonEncode(pending)});
  Future<void> _run(Future<void> Function() action) async {
    if (_disposed || busy) return;
    busy = true;
    failure = null;
    completed = null;
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
      stale = true;
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        requests = [];
        total = 0;
        ready = false;
        pending = null;
        try {
          await _persist();
        } catch (_) {
          failure = const UnknownFailure();
        }
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _fetch({bool more = false}) async {
    final result = (await api.customerLinksControllerList(
            limit: 50, offset: more ? requests.length : 0))
        .data!;
    if (_disposed) return;
    requests = more
        ? [...requests, ...result.items].fold<List<LinkRequestResponse>>([],
            (rows, row) {
            if (!rows.any((r) => r.id == row.id)) rows.add(row);
            return rows;
          })
        : result.items;
    total = result.total;
    ready = true;
    stale = false;
  }

  Future<void> load() => _run(() async {
        if (!_restored) {
          final saved = await store.read(owner);
          if (_disposed) return;
          if (saved['pending'] != null) {
            final value =
                Map<String, String>.from(jsonDecode(saved['pending']!) as Map);
            if (!{'accept', 'decline'}.contains(value['action']) ||
                !Uuid.isValidUUID(fromString: value['id'] ?? '') ||
                !Uuid.isValidUUID(fromString: value['key'] ?? '')) {
              throw const UnknownFailure(code: 'INVALID_SAVED_LINK_DECISION');
            }
            pending = value;
          }
          _restored = true;
        }
        await _fetch();
      });
  Future<void> more() => _run(() async {
        if (!ready || stale || requests.length >= total) return;
        await _fetch(more: true);
      });
  Future<void> decide(String id, bool accept) async {
    if (!canDecide || !requests.any((r) => r.id == id)) return;
    await _run(() async {
      pending = {
        'id': id,
        'action': accept ? 'accept' : 'decline',
        'key': const Uuid().v4()
      };
      await _send();
    });
  }

  Future<void> retryPending() => _run(_send);
  Future<void> _send() async {
    final request = pending;
    if (request == null || _disposed) return;
    await _persist();
    if (_disposed) return;
    final accept = request['action'] == 'accept';
    try {
      final response = accept
          ? await api.customerLinksControllerAccept(
              id: request['id']!, idempotencyKey: request['key']!)
          : await api.customerLinksControllerDecline(
              id: request['id']!, idempotencyKey: request['key']!);
      if (response.data?.id != request['id'] ||
          response.data?.decision.value != (accept ? 'ACCEPTED' : 'DECLINED')) {
        throw const UnknownFailure();
      }
    } catch (error) {
      if (_disposed) rethrow;
      final f = error is DioException ? mapDioFailure(error) : error;
      if (f is NotFoundFailure ||
          f is ConflictFailure ||
          f is ValidationFailure ||
          (f is BusinessRuleFailure && f.code != 'RATE_LIMITED')) {
        pending = null;
        try {
          await _persist();
        } catch (_) {
          pending = request;
          rethrow;
        }
      }
      rethrow;
    }
    if (_disposed) return;
    pending = null;
    try {
      await _persist();
    } catch (_) {
      pending = request;
      rethrow;
    }
    completed = accept ? 'ACCEPTED' : 'DECLINED';
    requests = requests.where((r) => r.id != request['id']).toList();
    // A later list failure cannot turn an acknowledged decision into a retry.
    await _fetch();
  }
}
