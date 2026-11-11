import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../core/l10n/l10n.dart';
import '../auth/session_controller.dart';
import 'notifications_controller.dart';

Future<bool> confirmNotificationAction(
        BuildContext context, String title) async =>
    await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              scrollable: true,
              title: Text(context.l10n.routeNotifications),
              content: Text(title),
              actions: [
                SbButton(
                    label: context.l10n.notificationsCancel,
                    variant: SbButtonVariant.tertiary,
                    onPressed: () => Navigator.pop(dialogContext, false)),
                SbButton(
                    label: context.l10n.notificationsContinue,
                    onPressed: () => Navigator.pop(dialogContext, true)),
              ],
            )) ??
    false;

Future<void> openNotification(BuildContext context, WidgetRef ref,
    GoRouter router, String id, String role) async {
  final before = ref.read(sessionProvider).user;
  if (before == null || !before.roles.any((held) => held.value == role)) return;
  try {
    final model = ref.read(notificationsProvider);
    final item = await model.find(id, role);
    if (!context.mounted ||
        item == null ||
        !model.alive ||
        ref.read(sessionProvider).user?.id != before.id) {
      return;
    }
    if (before.activeRole?.value != role) {
      if (!await confirmNotificationAction(
          context,
          context.l10n.notificationsSwitchRole(role == 'VENDOR'
              ? context.l10n.notificationsVendor
              : context.l10n.notificationsCustomer))) {
        return;
      }
      if (!context.mounted || ref.read(sessionProvider).user?.id != before.id) {
        return;
      }
      await ref.read(sessionProvider.notifier).selectRole(role);
    }
    if (!context.mounted ||
        ref.read(sessionProvider).user?.id != before.id ||
        ref.read(sessionProvider).user?.activeRole?.value != role) {
      return;
    }
    if (!await model.read(role, id: item.id)) return;
    if (context.mounted &&
        model.alive &&
        ref.read(sessionProvider).user?.id == before.id &&
        ref.read(sessionProvider).user?.activeRole?.value == role) {
      router.go(notificationLocation(item));
    }
  } catch (_) {
    // No provider payload, ID, token or account details in diagnostics/UI.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.notificationsOpenFailed)));
    }
  }
}
