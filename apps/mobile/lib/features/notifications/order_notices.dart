// T-052: owned inbox data can request reads, never set local order state.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import '../auth/session_controller.dart';

class OrderNotice {
  const OrderNotice(this.account, this.role, this.orderId);
  final String account, role, orderId;
}

final orderNoticeProvider = StateProvider<OrderNotice?>((ref) {
  ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  return null;
});

OrderNotice? ownedOrderNotice(InboxItem item, String account) {
  final role = item.role.value;
  final types = role == 'VENDOR'
      ? const {'ORDER_NEW', 'ORDER_CANCELLED'}
      : const {
          'ORDER_ACCEPTED',
          'ORDER_REJECTED',
          'OUT_FOR_DELIVERY',
          'ORDER_DELIVERED',
          'DELIVERY_FAILED'
        };
  if (!types.contains(item.type)) return null;
  final match = RegExp('^/${role.toLowerCase()}/orders/'
          r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$')
      .firstMatch(item.path);
  return match == null ? null : OrderNotice(account, role, match.group(1)!);
}

/// Only providers already used by the UI subscribe, avoiding feature creation,
/// storage access or requests merely because a background notification arrived.
void listenForOrderNotices(
    Ref ref, String? account, String role, Future<void> Function() refresh) {
  ref.listen(orderNoticeProvider, (_, notice) {
    final user = ref.read(sessionProvider).user;
    if (notice != null &&
        notice.account == account &&
        notice.role == role &&
        user?.id == account &&
        user?.activeRole?.value == role) {
      unawaited(refresh());
    }
  });
}
