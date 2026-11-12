// T-047 / FR-291: server-owned addresses and encrypted explicit retries.
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

final addressesProvider =
    ChangeNotifierProvider.autoDispose<AddressesController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  final model = AddressesController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:addresses');
  ref.onDispose(client.close);
  if (identity.$1 != null && identity.$2 == 'CUSTOMER') {
    Future.microtask(model.load);
  }
  return model;
});

class AddressesController extends ChangeNotifier {
  AddressesController(NetworkClient client, this.store, this.owner)
      : api = CustomerAddressesApi(client.dio);
  final CustomerAddressesApi api;
  final OnboardingDrafts store;
  final String owner;
  List<AddressResponse> addresses = [];
  Map<String, dynamic>? pending;
  AppFailure? failure;
  bool ready = false,
      busy = false,
      completed = false,
      stale = false,
      _disposed = false,
      _restored = false;
  bool get canEdit => ready && !busy && !stale && pending == null && !_disposed;
  bool get retryExpired {
    if (pending == null) return false;
    final created = pending!['created'] as int? ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - created;
    return age < 0 || age >= const Duration(hours: 24).inMilliseconds;
  }

  AddressResponse? find(String id) {
    for (final row in addresses) {
      if (row.id == id) return row;
    }
    return null;
  }

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
    completed = false;
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
      stale = true;
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        addresses = [];
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
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _fetch() async {
    final rows = (await api.addressesControllerList()).data!.items;
    if (_disposed) return;
    addresses = rows;
    ready = true;
    stale = false;
  }

  Future<void> load() => _run(() async {
        if (!_restored) {
          final saved = await store.read(owner);
          if (_disposed) return;
          pending = saved['pending'] == null
              ? null
              : Map<String, dynamic>.from(jsonDecode(saved['pending']!) as Map);
          _restored = true;
        }
        await _fetch();
      });
  Future<bool> save(AddressInput input, {String? id}) =>
      _mutate(id == null ? 'POST' : 'PATCH', id, input.toJson());
  Future<bool> makeDefault(String id) =>
      _mutate('PATCH', id, {'isDefault': true});
  Future<bool> remove(String id) => _mutate('DELETE', id, {});
  Future<bool> _mutate(
      String method, String? id, Map<String, dynamic> body) async {
    if (!canEdit) return false;
    await _run(() async {
      pending = {
        'method': method,
        'id': id,
        'body': body,
        'key': const Uuid().v4(),
        'created': DateTime.now().millisecondsSinceEpoch
      };
      await _send();
    });
    return !_disposed && completed;
  }

  Future<void> retryPending() => _run(() async {
        if (retryExpired) {
          throw const BusinessRuleFailure(code: 'ADDRESS_RETRY_EXPIRED');
        }
        await _send();
      });
  // Only the user can dismiss an expired retry after reviewing a fresh server list.
  Future<void> dismissExpired() => _run(() async {
        if (!retryExpired || !ready || stale) return;
        pending = null;
        await _persist();
      });
  Future<void> _send() async {
    final request = pending;
    if (request == null || _disposed) return;
    await _persist();
    if (_disposed) return;
    final key = request['key'] as String, id = request['id'] as String?;
    final body = Map<String, dynamic>.from(request['body'] as Map);
    try {
      switch (request['method']) {
        case 'POST':
          await api.addressesControllerCreate(
              idempotencyKey: key, addressInput: AddressInput.fromJson(body));
        case 'PATCH':
          await api.addressesControllerPatch(
              id: id!,
              idempotencyKey: key,
              addressPatch: AddressPatch.fromJson(body));
        case 'DELETE':
          await api.addressesControllerRemove(id: id!, idempotencyKey: key);
        default:
          throw ValidationFailure(fieldErrors: const {});
      }
    } catch (error) {
      if (_disposed) rethrow;
      final f = error is DioException ? mapDioFailure(error) : error;
      if (f is ValidationFailure ||
          f is ConflictFailure ||
          f is NotFoundFailure ||
          (f is BusinessRuleFailure && f.code != 'RATE_LIMITED')) {
        pending = null;
        await _persist();
      }
      rethrow;
    }
    if (_disposed) return;
    completed = true;
    pending = null;
    try {
      await _persist();
    } catch (_) {
      pending = request;
      rethrow;
    }
    if (!_disposed) await _fetch();
  }
}
