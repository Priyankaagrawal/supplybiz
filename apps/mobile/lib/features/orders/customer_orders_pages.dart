// S-C-13/14 / T-051. Owned snapshots and server event times; no live map.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../../core/storage/customer_device.dart';
import '../discovery/cart_controller.dart';
import '../discovery/discovery_widgets.dart';
import '../home/home_page.dart' show homeStatus;
import 'customer_orders_controller.dart';
import 'orders_pages.dart' show orderFailure, orderReason;

class CustomerOrderFeedback extends StatelessWidget {
  const CustomerOrderFeedback(this.model, {super.key});
  final CustomerOrdersController model;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (model.busy) const SbSkeleton(),
      if (model.failure != null)
        Semantics(
            liveRegion: true, child: Text(orderFailure(model.failure!, l))),
      if (model.stale && (model.ready || model.details.isNotEmpty))
        Text(l.ordersCached),
      if (model.pending != null) ...[
        Text(l.ordersPending),
        SbButton(
            label: l.ordersRetrySaved,
            onPressed: model.busy ? null : model.retry)
      ]
    ]);
  }
}

class CustomerOrdersPage extends ConsumerStatefulWidget {
  const CustomerOrdersPage({super.key});
  @override
  ConsumerState<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends ConsumerState<CustomerOrdersPage> {
  CustomerOrdersController? initialized;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(customerOrdersProvider), l = context.l10n;
    if (initialized != m) {
      initialized = m;
      Future.microtask(m.load);
    }
    return Scaffold(
        appBar: AppBar(title: Text(l.navOrders), actions: const [CartButton()]),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      CustomerOrderFeedback(m),
                      SbButton(
                          label: l.authRetry,
                          onPressed: m.busy ? null : m.load),
                      DropdownButtonFormField<String>(
                          key: ValueKey(m.tab),
                          initialValue: m.tab,
                          isExpanded: true,
                          decoration:
                              InputDecoration(labelText: l.ordersFilter),
                          items: ['ALL', 'ONGOING', 'DELIVERED', 'CANCELLED']
                              .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s == 'ALL'
                                      ? l.customersAll
                                      : s == 'ONGOING'
                                          ? l.customerOrdersOngoing
                                          : homeStatus(l, s))))
                              .toList(),
                          onChanged: m.busy
                              ? null
                              : (s) {
                                  if (s != null) m.load(filter: s);
                                }),
                      if (m.ready && m.items.isEmpty)
                        SbEmpty(message: l.ordersEmpty),
                      for (final o in m.items)
                        Card(
                            child: ListTile(
                                minVerticalPadding: 16,
                                minTileHeight: 72,
                                leading: const Icon(Icons.inventory_2_outlined),
                                title: Text(o.orderNo),
                                subtitle: Text(
                                    '${(o.itemSummary ?? []).join(', ')}\n${DateFormat('yyyy-MM-dd').format(o.deliveryDate)} · ${formatInr(int.parse(o.totalPaise))}\n${homeStatus(l, o.status)}'),
                                onTap: () => CustomerOrderRoute(o.id)
                                    .push<void>(context))),
                      if (m.offset < m.total)
                        SbButton(
                            label: l.ordersMore,
                            onPressed: m.busy ? null : () => m.load(more: true))
                    ]))));
  }
}

class CustomerOrderPage extends ConsumerStatefulWidget {
  const CustomerOrderPage({required this.id, super.key});
  final String id;
  @override
  ConsumerState<CustomerOrderPage> createState() => _CustomerOrderPageState();
}

class _CustomerOrderPageState extends ConsumerState<CustomerOrderPage> {
  CustomerOrdersController? initialized;
  String? initializedId;
  bool adding = false;
  @override
  void dispose() {
    initialized?.leave(widget.id);
    super.dispose();
  }

  Future<void> reorder(CustomerOrdersController m) async {
    if (adding) return;
    setState(() => adding = true);
    try {
      var preview = await m.reorder(widget.id);
      if (!mounted || !m.alive || preview == null) return;
      final l = context.l10n;
      final approved = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                      title: Text(l.customerOrdersReview),
                      content: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            for (final i in preview.items)
                              Text(
                                  '${i.product.name} × ${i.qty} · ${formatInr(i.product.sellingPricePaise)}'),
                            if (preview.unavailable.isNotEmpty)
                              Text(l.customerOrdersUnavailable),
                            for (final i in preview.unavailable)
                              Text(
                                  '${i.name}: ${i.reason.value == 'BELOW_MOQ' ? l.customerOrdersMoq : i.reason.value == 'INSUFFICIENT_STOCK' ? l.customerOrdersNoStock : l.customerOrdersRemoved}')
                          ])),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l.productsCancel)),
                        TextButton(
                            onPressed: preview.items.isEmpty
                                ? null
                                : () => Navigator.pop(context, true),
                            child: Text(l.customerOrdersAdd))
                      ])) ??
          false;
      if (!mounted || !m.alive || !approved) return;
      final cart = ref.read(cartProvider);
      if (!cart.ready) await cart.load();
      if (!mounted || !m.alive) return;
      var result = await cart.addReorder(preview);
      if (!mounted || !m.alive) return;
      if (result == CartChange.replaceVendor) {
        if (!await discoveryConfirm(context, l.discoveryReplaceCart) ||
            !mounted ||
            !m.alive) {
          return;
        }
        // Refresh before replacing another vendor's cart; review any new changes.
        final fresh = await m.reorder(widget.id);
        if (!mounted || !m.alive || fresh == null) return;
        if (fresh.toJson().toString() != preview.toJson().toString()) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.discoveryChanged)));
          return;
        }
        result = await cart.addReorder(fresh, replace: true);
      }
      if (mounted && m.alive) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result == CartChange.saved
                ? l.discoveryAdded
                : l.discoveryCartError)));
      }
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(customerOrdersProvider), l = context.l10n;
    if (initialized != m || initializedId != widget.id) {
      initialized?.leave(initializedId ?? '');
      initialized = m;
      initializedId = widget.id;
      Future.microtask(() => m.open(widget.id));
    }
    final d = m.details[widget.id], can = m.canActOn(widget.id);
    return Scaffold(
        appBar: AppBar(
            title: Text(d?.orderNo ?? l.ordersDetails),
            actions: const [CartButton()]),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: () => m.open(widget.id),
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      CustomerOrderFeedback(m),
                      SbButton(
                          label: l.authRetry,
                          onPressed: m.busy ? null : () => m.open(widget.id)),
                      if (d == null && !m.busy && m.failure == null)
                        SbEmpty(message: l.ordersEmpty),
                      if (d != null) ...[
                        Semantics(
                            liveRegion: true,
                            child: Text(homeStatus(l, d.status),
                                style: Theme.of(context).textTheme.titleLarge)),
                        Text(
                            '${DateFormat('yyyy-MM-dd').format(d.deliveryDate)} · ${d.timeSlot}'),
                        Text(d.vendorName ?? l.ordersVendor),
                        if (d.vendorMobile != null)
                          SbButton(
                              label: l.customerOrdersCallVendor,
                              onPressed: () async {
                                final ok = await const CustomerDevice()
                                    .dial(d.vendorMobile!);
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              l.customersDialUnavailable)));
                                }
                              }),
                        Text([
                          d.address.line1,
                          d.address.line2,
                          d.address.landmark,
                          d.address.city,
                          d.address.state,
                          d.address.pincode
                        ].where((s) => s.isNotEmpty).join(', ')),
                        for (final i in d.items)
                          Text(
                              '${i.name} (${i.unitValue} ${i.unitType})\n${formatInr(int.parse(i.unitPricePaise))} × ${i.qty} = ${formatInr(int.parse(i.lineTotalPaise))}'),
                        Text(l.checkoutSubtotal(
                            formatInr(int.parse(d.subtotalPaise)))),
                        Text(l.checkoutDelivery(
                            formatInr(int.parse(d.deliveryChargePaise)))),
                        Text(l.ordersDiscount(
                            formatInr(int.parse(d.discountPaise)))),
                        Text(l
                            .checkoutTotal(formatInr(int.parse(d.totalPaise)))),
                        Text(d.paymentStatus == 'PAID'
                            ? l.ordersPaid
                            : l.ordersUnpaid),
                        Text(l.ordersTimeline,
                            style: Theme.of(context).textTheme.titleMedium),
                        for (final status in [
                          'ACCEPTED',
                          'PREPARING',
                          'OUT_FOR_DELIVERY',
                          'DELIVERED'
                        ])
                          _TimelineStep(d, status),
                        for (final reason in [
                          d.rejectReason,
                          d.cancelReason,
                          d.failReason
                        ].whereType<String>())
                          Text(orderReason(l, reason)),
                        if (d.status == 'NEW')
                          SbButton(
                              label: l.customerOrdersCancel,
                              variant: SbButtonVariant.destructive,
                              onPressed: !can
                                  ? null
                                  : () async {
                                      if (await discoveryConfirm(context,
                                              l.customerOrdersCancelConfirm) &&
                                          mounted &&
                                          m.alive) {
                                        await m.cancel(d.id);
                                      }
                                    }),
                        if (['DELIVERED', 'FAILED', 'REJECTED', 'CANCELLED']
                            .contains(d.status))
                          SbButton(
                              label: l.customerOrdersReorder,
                              onPressed:
                                  can && !adding ? () => reorder(m) : null),
                      ]
                    ]))));
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep(this.order, this.status);
  final OrderDetail order;
  final String status;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final events = order.timeline.where((e) => e.status == status);
    final text = events.isEmpty
        ? l.customerOrdersNotYet
        : '${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(events.first.at).toUtc().add(const Duration(hours: 5, minutes: 30)))} ${l.ordersIst}';
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
            '${status == 'ACCEPTED' ? l.customerOrdersConfirmed : status == 'PREPARING' ? l.customerOrdersPacked : homeStatus(l, status)} · $text'));
  }
}
