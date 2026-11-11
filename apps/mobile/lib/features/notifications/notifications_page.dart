// S-V-18 / S-C-26 / S-COM-09: role inbox, preferences and permission explanation.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../core/l10n/l10n.dart';
import '../auth/session_controller.dart';
import '../onboarding/onboarding_controller.dart';
import 'notification_navigation.dart';
import 'notifications_controller.dart';
import 'push_gateway.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});
  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String? _loadedRole;
  bool _permissionBusy = false;
  String? _permissionMessage;
  Future<void> _enable() async {
    final gateway = ref.read(pushGatewayProvider);
    if (!gateway.available || _permissionBusy) return;
    final uid = ref.read(sessionProvider).user?.id;
    if (uid == null ||
        !await confirmNotificationAction(
            context, context.l10n.notificationsPermissionBody)) {
      return;
    }
    if (!mounted || ref.read(sessionProvider).user?.id != uid) return;
    setState(() => _permissionBusy = true);
    try {
      final allowed = await gateway.permitted(request: true);
      if (!mounted || ref.read(sessionProvider).user?.id != uid) return;
      final key = '${ref.read(authConfigProvider).baseUrl}:$uid:push-consent';
      await ref.read(onboardingDraftsProvider).write(key, {'enabled': 'true'});
      if (!mounted || ref.read(sessionProvider).user?.id != uid) return;
      ref.read(pushRefreshProvider.notifier).state++;
      setState(() => _permissionMessage = allowed
          ? context.l10n.notificationsPermissionAllowed
          : context.l10n.notificationsPermissionDenied);
    } catch (_) {
      if (mounted) {
        setState(
            () => _permissionMessage = context.l10n.notificationsOpenFailed);
      }
    } finally {
      if (mounted) setState(() => _permissionBusy = false);
    }
  }

  String _label(String category) => switch (category) {
        'ORDERS' => context.l10n.navOrders,
        'PAYMENTS' => context.l10n.notificationsPayments,
        'DELIVERY' => context.l10n.notificationsDelivery,
        'SYSTEM' => context.l10n.notificationsSystem,
        _ => context.l10n.notificationsAll,
      };
  String _age(DateTime timestamp) {
    final age = DateTime.now().toUtc().difference(timestamp.toUtc());
    if (age.inMinutes < 1) return context.l10n.notificationsNow;
    if (age.inHours < 1) {
      return context.l10n.notificationsMinutes(age.inMinutes);
    }
    if (age.inDays < 1) return context.l10n.notificationsHours(age.inHours);
    return context.l10n.notificationsDays(age.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(sessionProvider).user;
    final model = ref.watch(notificationsProvider);
    final role = user?.activeRole?.value;
    if (role != _loadedRole && role != null && !model.busy) {
      _loadedRole = role;
      Future.microtask(() => model.load(role));
    }
    final enabled =
        !model.busy && !model.hasPending && user != null && model.role == role;
    final prefs = model.preferences;
    Widget preference(String name, bool value, void Function(bool) change) =>
        SwitchListTile(
            title: Text(name),
            value: value,
            onChanged: enabled ? change : null,
            contentPadding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.padded);
    void save({bool? orders, bool? payments, bool? delivery, bool? system}) {
      if (prefs == null) return;
      model.save(NotificationPreferences(
          orders: orders ?? prefs.orders,
          payments: payments ?? prefs.payments,
          delivery: delivery ?? prefs.delivery,
          system: system ?? prefs.system));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeNotifications)),
      body: SafeArea(
          child: RefreshIndicator(
        onRefresh: () async {
          if (role != null) await model.load(role, model.category);
        },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (user == null) Text(l10n.notificationsSignIn),
          if (model.busy) const LinearProgressIndicator(),
          if (model.failure != null) ...[
            Text(model.failure!.toMessage(l10n),
                semanticsLabel: model.failure!.toMessage(l10n)),
            SbButton(
                label: model.hasPending
                    ? l10n.notificationsRetrySaved
                    : l10n.notificationsRefresh,
                onPressed: model.busy
                    ? null
                    : () => model.hasPending
                        ? model.retry()
                        : model.load(role ?? 'CUSTOMER', model.category)),
          ],
          Text(l10n.notificationsUnread(model.unread),
              style: Theme.of(context).textTheme.titleMedium),
          Wrap(spacing: 8, children: [
            for (final category in [
              'ALL',
              'ORDERS',
              'PAYMENTS',
              if (role == 'VENDOR') 'DELIVERY',
              'SYSTEM'
            ])
              ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: FilterChip(
                      label: Text(_label(category)),
                      selected: model.category == category,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected:
                          enabled ? (_) => model.load(role!, category) : null)),
          ]),
          SbButton(
              label: l10n.notificationsReadAll,
              variant: SbButtonVariant.secondary,
              onPressed:
                  enabled && model.unread > 0 ? () => model.read(role!) : null),
          const SizedBox(height: 8),
          SbButton(
              label: l10n.notificationsClear,
              variant: SbButtonVariant.destructive,
              onPressed: enabled
                  ? () async {
                      if (await confirmNotificationAction(
                              context, l10n.notificationsClearConfirm) &&
                          mounted &&
                          model.alive) {
                        await model.clear();
                      }
                    }
                  : null),
          if (model.ready && model.items.isEmpty)
            Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.notificationsEmpty)),
          for (final item in model.items)
            Card(
                child: Semantics(
                    button: true,
                    label: item.readAt == null
                        ? l10n.notificationsUnreadItem
                        : l10n.notificationsReadItem,
                    child: ListTile(
                      minVerticalPadding: 16,
                      leading: Icon(item.readAt == null
                          ? Icons.mark_email_unread_outlined
                          : Icons.drafts_outlined),
                      title: Text(item.title),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.body),
                            Semantics(
                                label: DateFormat.yMMMd('en')
                                    .add_jm()
                                    .format(item.createdAt.toLocal()),
                                child: Text(_age(item.createdAt))),
                          ]),
                      onTap: enabled
                          ? () => openNotification(context, ref,
                              GoRouter.of(context), item.id, item.role.value)
                          : null,
                    ))),
          const Divider(),
          Text(l10n.notificationsPreferences,
              style: Theme.of(context).textTheme.titleLarge),
          Text(l10n.notificationsMandatory),
          if (prefs != null) ...[
            preference(_label('ORDERS'), prefs.orders, (v) => save(orders: v)),
            preference(
                _label('PAYMENTS'), prefs.payments, (v) => save(payments: v)),
            if (role == 'VENDOR')
              preference(
                  _label('DELIVERY'), prefs.delivery, (v) => save(delivery: v)),
            preference(_label('SYSTEM'), prefs.system, (v) => save(system: v)),
          ],
          const SizedBox(height: 16),
          Text(l10n.notificationsPermissionBody),
          if (!ref.read(pushGatewayProvider).available)
            Text(l10n.notificationsUnavailable),
          if (_permissionMessage != null) Text(_permissionMessage!),
          SbButton(
              label: l10n.notificationsEnable,
              loading: _permissionBusy,
              onPressed: enabled && ref.read(pushGatewayProvider).available
                  ? _enable
                  : null),
          const SizedBox(height: 24),
        ]),
      )),
    );
  }
}
