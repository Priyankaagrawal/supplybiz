// T-033 / US-100–101: account-scoped inbox and explicit idempotent mutations.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../auth/session_controller.dart';

final notificationsProvider =
    ChangeNotifierProvider<NotificationsController>((ref) {
  final uid = ref.watch(sessionProvider.select((s) => s.user?.id));
  final client = NetworkClient(
      baseUrl: Uri.parse(ref.read(authConfigProvider).baseUrl)
          .replace(path: '')
          .toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  return NotificationsController(NotificationsApi(client.dio), uid);
});

class NotificationsController extends ChangeNotifier {
  NotificationsController(this.api, this.uid);
  final NotificationsApi api;
  final String? uid;
  List<InboxItem> items = [];
  NotificationPreferences? preferences;
  AppFailure? failure;
  bool busy = false, ready = false, _disposed = false;
  int unread = 0;
  String role = 'CUSTOMER', category = 'ALL';
  Future<void> Function()? _pending;
  bool get hasPending => _pending != null;
  bool get alive => !_disposed;

  Future<bool> _run(Future<void> Function() action) async {
    if (busy || _disposed || uid == null) return false;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await action();
      return !_disposed;
    } catch (error) {
      if (!_disposed) {
        failure = error is DioException
            ? mapDioFailure(error)
            : const UnknownFailure();
        if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
          items = [];
          unread = 0;
          preferences = null;
          ready = false;
          _pending = null;
        }
        // An HTTP rejection is definitive. Transport/server failures may have committed.
        if (error is DioException &&
            (error.response?.statusCode ?? 500) < 500) {
          _pending = null;
        }
      }
      return false;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetch() async {
    final rows = <InboxItem>[];
    int offset = 0;
    while (!_disposed) {
      final page = (await api.notificationsControllerList(
              role: role, category: category, limit: 100, offset: offset))
          .data!;
      if (_disposed) return;
      rows.addAll(page.items);
      unread = page.unreadCount;
      offset += page.items.length;
      if (offset >= page.total || page.items.isEmpty) break;
    }
    if (!_disposed) {
      items = rows;
      ready = true;
    }
  }

  Future<bool> load(String nextRole, [String nextCategory = 'ALL']) =>
      _run(() async {
        if (role != nextRole || category != nextCategory) {
          items = [];
          unread = 0;
          ready = false;
        }
        role = nextRole;
        category = nextCategory;
        await _fetch();
        final prefs = (await api.notificationsControllerPreferences()).data!;
        if (!_disposed) preferences = prefs;
      });

  Future<bool> _mutate(Future<void> Function(String key) action) async {
    if (_pending != null || busy || _disposed) return false;
    final key = const Uuid().v4();
    _pending = () async {
      await action(key);
      if (!_disposed) _pending = null;
    };
    return retry();
  }

  Future<bool> retry() => _run(() async {
        await _pending?.call();
        if (!_disposed) await _fetch();
      });
  Future<bool> read(String targetRole, {String? id}) => _mutate((key) async {
        await api.notificationsControllerRead(
            idempotencyKey: key,
            readNotifications: ReadNotifications.fromJson({
              'role': targetRole,
              if (id == null) 'all': true else 'ids': [id],
            }));
      });
  Future<bool> clear() {
    final targetRole = role;
    return _mutate((key) async {
      await api.notificationsControllerClear(
          idempotencyKey: key, role: targetRole);
    });
  }

  Future<bool> save(NotificationPreferences value) => _mutate((key) async {
        final saved = (await api.notificationsControllerSavePreferences(
                idempotencyKey: key, notificationPreferences: value))
            .data!;
        if (!_disposed) preferences = saved;
      });

  /// Never use a push's title/path/type as authority. Resolve the ID in the owned inbox.
  Future<InboxItem?> find(String id, String targetRole) async {
    if (_disposed ||
        uid == null ||
        !{'VENDOR', 'CUSTOMER'}.contains(targetRole) ||
        !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id)) {
      return null;
    }
    int offset = 0;
    while (!_disposed) {
      final page = (await api.notificationsControllerList(
              role: targetRole, limit: 100, offset: offset))
          .data!;
      if (_disposed) return null;
      for (final item in page.items) {
        if (item.id == id && item.role.value == targetRole) return item;
      }
      offset += page.items.length;
      if (offset >= page.total || page.items.isEmpty) break;
    }
    return null;
  }

  Future<void> register(String? token) async {
    if (_disposed || uid == null) return;
    await api.notificationsControllerDevice(
        idempotencyKey: const Uuid().v4(),
        devicePushInput:
            DevicePushInput(pushEnabled: token != null, pushToken: token));
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

/// Only implemented application destinations. Older server subscription paths are
/// normalized here; future domain screens fall back to the inbox until implemented.
String notificationLocation(InboxItem item) {
  final path = item.path;
  final role = item.role.value.toLowerCase();
  const id =
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}';
  if (path == '/common/settings') return path;
  if (role == 'vendor' && path == '/vendor/onboarding/status') return path;
  if (RegExp('^/$role/orders/$id\$').hasMatch(path)) return path;
  if (role == 'vendor' &&
      RegExp('^/vendor/customers/subscriptions/$id\$').hasMatch(path)) {
    return path;
  }
  if (role == 'customer') {
    if (RegExp('^/customer/khata/$id\$').hasMatch(path) ||
        RegExp('^/customer/orders/subscriptions/$id\$').hasMatch(path)) {
      return path;
    }
    if (RegExp('^/customer/subscriptions/$id\$').hasMatch(path)) {
      return path.replaceFirst(
          '/customer/subscriptions/', '/customer/orders/subscriptions/');
    }
    if (path == '/customer/subscriptions') return '/customer/orders';
  }
  return '/common/notifications';
}
