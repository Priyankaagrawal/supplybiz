import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../auth/session_controller.dart';
import '../onboarding/onboarding_controller.dart';
import 'order_notices.dart';
import 'notification_navigation.dart';
import 'notifications_controller.dart';
import 'push_gateway.dart';

/// FCM notification payloads are rendered by Android in the background. Foreground
/// alerts are deliberately in-app; all taps resolve an owned inbox row first.
class NotificationHost extends ConsumerStatefulWidget {
  const NotificationHost(
      {required this.router, required this.child, super.key});
  final GoRouter router;
  final Widget child;
  @override
  ConsumerState<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends ConsumerState<NotificationHost>
    with WidgetsBindingObserver {
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Map<String, dynamic>? _cold;
  String? _uid;
  bool _opening = false;
  bool _syncing = false, _again = false;
  final _seen = <String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final gateway = ref.read(pushGatewayProvider);
    if (!gateway.available) return;
    _subscriptions.add(
        gateway.foreground.listen((data) => _receive(data, foreground: true)));
    _subscriptions.add(gateway.opened.listen(_receive));
    _subscriptions.add(gateway.tokens.listen((_) => _sync()));
    Future.microtask(() async {
      try {
        _cold = await gateway.initial();
        if (mounted) _sync();
      } catch (_) {/* retry from inbox */}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  Future<void> _sync() async {
    if (_syncing) {
      _again = true;
      return;
    }
    _syncing = true;
    try {
      await _syncOnce();
    } finally {
      _syncing = false;
      if (_again && mounted) {
        _again = false;
        unawaited(_sync());
      }
    }
  }

  Future<void> _syncOnce() async {
    if (!mounted) return;
    final user = ref.read(sessionProvider).user;
    final gateway = ref.read(pushGatewayProvider);
    if (user == null || !gateway.available) return;
    if (_cold != null) {
      final data = _cold!;
      _cold = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _receive(data);
      });
    }
    final model = ref.read(notificationsProvider);
    try {
      final key =
          '${ref.read(authConfigProvider).baseUrl}:${user.id}:push-consent';
      final consent = await ref.read(onboardingDraftsProvider).read(key);
      if (!mounted ||
          !model.alive ||
          ref.read(sessionProvider).user?.id != user.id ||
          consent['enabled'] != 'true') {
        return;
      }
      final token = await gateway.permitted() ? await gateway.token() : null;
      if (mounted &&
          model.alive &&
          ref.read(sessionProvider).user?.id == user.id) {
        await model.register(token);
      }
    } catch (_) {
      /* Retry registration on resume/session/token refresh. Never fake success. */
    }
  }

  Future<void> _receive(Map<String, dynamic> data,
      {bool foreground = false}) async {
    if (!mounted || _opening) return;
    final user = ref.read(sessionProvider).user;
    final id = data['notificationId'], role = data['role'];
    if (user == null || id is! String || role is! String) return;
    final context = widget
        .router.routerDelegate.navigatorKey.currentState?.overlay?.context;
    if (context == null) return;
    if (foreground) {
      final account = user.id;
      try {
        final model = ref.read(notificationsProvider);
        final item = await model.find(id, role);
        if (!mounted ||
            !context.mounted ||
            !model.alive ||
            item == null ||
            ref.read(sessionProvider).user?.id != account ||
            !_seen.add(id)) {
          return;
        }
        if (_seen.length > 100) _seen.remove(_seen.first);
        final notice = ownedOrderNotice(item, account);
        if (notice != null &&
            ref.read(sessionProvider).user?.activeRole?.value == role) {
          ref.read(orderNoticeProvider.notifier).state = notice;
        }
        if (model.ready &&
            model.role == role &&
            ref.read(sessionProvider).user?.activeRole?.value == role) {
          unawaited(model.load(role, model.category));
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.notificationsNew),
            action: SnackBarAction(
                label: context.l10n.notificationsOpen,
                onPressed: () {
                  if (mounted &&
                      ref.read(sessionProvider).user?.id == account) {
                    _receive(data);
                  }
                })));
      } catch (_) {/* Inbox remains the source of truth. */}
    } else {
      _opening = true;
      try {
        await openNotification(context, ref, widget.router, id, role);
      } finally {
        _opening = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pushRefreshProvider, (_, __) => _sync());
    ref.listen(sessionProvider, (previous, next) {
      if (_uid != next.user?.id) {
        _uid = next.user?.id;
        _seen.clear();
        if (previous?.user != null) {
          _cold = null;
          widget
              .router.routerDelegate.navigatorKey.currentState?.overlay?.context
              .letHideNotifications();
        }
      }
      _sync();
    });
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }
}

extension on BuildContext {
  void letHideNotifications() =>
      ScaffoldMessenger.maybeOf(this)?.clearSnackBars();
}
