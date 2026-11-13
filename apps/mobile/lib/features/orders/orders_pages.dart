// S-V-08–10 / T-048. Completion/payment collection belongs to T-049/T-050.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/app_failure.dart';
import '../../core/router/routes.dart';
import '../../core/storage/customer_device.dart';
import '../home/home_page.dart' show homeStatus;
import 'orders_controller.dart';

String orderReason(AppLocalizations l, String reason) => switch (reason) {
      'CUSTOMER_UNAVAILABLE' => l.ordersCustomerUnavailable,
      'OUT_OF_STOCK' => l.ordersOutOfStock,
      'NOT_SERVICEABLE' => l.ordersNotServiceable,
      'CUSTOMER_REQUEST' => l.ordersCustomerRequest,
      'OTHER' => l.ordersOther,
      _ => reason,
    };
String orderFailure(AppFailure f, AppLocalizations l) => switch (f.code) {
      'INVALID_STATE_TRANSITION' ||
      'VERSION_CONFLICT' =>
        l.ordersNoLongerAvailable,
      'REJECT_REASON_REQUIRED' => l.ordersReasonHelp,
      _ => f.toMessage(l),
    };
DateTime? orderFilterDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final parsed = DateTime.tryParse(value);
  return parsed != null && DateFormat('yyyy-MM-dd').format(parsed) == value
      ? parsed
      : null;
}

class OrderFeedback extends StatelessWidget {
  const OrderFeedback(this.model, {super.key});
  final VendorOrdersController model;
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
      ],
    ]);
  }
}

class VendorOrdersPage extends ConsumerStatefulWidget {
  const VendorOrdersPage({super.key});
  @override
  ConsumerState<VendorOrdersPage> createState() => _VendorOrdersPageState();
}

class _VendorOrdersPageState extends ConsumerState<VendorOrdersPage> {
  VendorOrdersController? initialized;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(vendorOrdersProvider), l = context.l10n;
    if (initialized != m) {
      initialized = m;
      Future.microtask(m.load);
    }
    return Scaffold(
        appBar: AppBar(title: Text(l.navOrders)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      OrderFeedback(m),
                      SbButton(
                          label: l.authRetry,
                          variant: SbButtonVariant.secondary,
                          onPressed: m.busy ? null : m.load),
                      DropdownButtonFormField<String>(
                          key: ValueKey('filter:${m.status}'),
                          initialValue: m.status,
                          isExpanded: true,
                          decoration:
                              InputDecoration(labelText: l.ordersFilter),
                          items: [
                            'ALL',
                            'NEW',
                            'ACCEPTED',
                            'PREPARING',
                            'OUT_FOR_DELIVERY',
                            'DELIVERED',
                            'CANCELLED',
                            'FAILED'
                          ]
                              .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                      s == 'ALL'
                                          ? l.customersAll
                                          : homeStatus(l, s),
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: m.busy
                              ? null
                              : (s) {
                                  if (s != null) m.load(filter: s);
                                }),
                      TextFormField(
                          key: ValueKey('search:${m.search}'),
                          initialValue: m.search,
                          enabled: !m.busy,
                          maxLength: 120,
                          textInputAction: TextInputAction.search,
                          decoration:
                              InputDecoration(labelText: l.ordersSearch),
                          onFieldSubmitted: (q) => m.load(query: q)),
                      TextFormField(
                          key: ValueKey('day:${m.date}'),
                          initialValue: m.date == null
                              ? ''
                              : DateFormat('yyyy-MM-dd').format(m.date!),
                          enabled: !m.busy,
                          decoration: InputDecoration(labelText: l.ordersDate),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) => v == null ||
                                  v.isEmpty ||
                                  orderFilterDate(v) != null
                              ? null
                              : l.ordersInvalidDate,
                          onFieldSubmitted: (v) {
                            if (v.isEmpty) {
                              m.load(clearDate: true);
                            } else if (orderFilterDate(v) != null) {
                              m.load(day: orderFilterDate(v));
                            }
                          }),
                      if (m.date != null)
                        SbButton(
                            label: l.ordersAllDates,
                            variant: SbButtonVariant.secondary,
                            onPressed:
                                m.busy ? null : () => m.load(clearDate: true)),
                      if (m.ready && m.items.isEmpty)
                        SbEmpty(message: l.ordersEmpty),
                      for (final row in m.items)
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(row.orderNo,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Text(homeStatus(l, row.status)),
                                      Text(
                                          '${DateFormat('yyyy-MM-dd').format(row.deliveryDate)} · ${row.timeSlot}'),
                                      Text(
                                          formatInr(int.parse(row.totalPaise))),
                                      SbButton(
                                          label: l.ordersOpen,
                                          onPressed: () =>
                                              VendorOrderRoute(row.id)
                                                  .push<void>(context)),
                                    ]))),
                      if (m.offset < m.total)
                        SbButton(
                            label: l.ordersMore,
                            onPressed:
                                m.busy ? null : () => m.load(more: true)),
                    ]))));
  }
}

class VendorOrderPage extends ConsumerStatefulWidget {
  const VendorOrderPage({required this.id, super.key});
  final String id;
  @override
  ConsumerState<VendorOrderPage> createState() => _VendorOrderPageState();
}

class _VendorOrderPageState extends ConsumerState<VendorOrderPage> {
  String? initialized;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(vendorOrdersProvider), l = context.l10n;
    final key = '${identityHashCode(m)}:${widget.id}';
    if (initialized != key) {
      initialized = key;
      Future.microtask(() => m.open(widget.id));
    }
    final d = m.details[widget.id], can = m.canActOn(widget.id);
    return Scaffold(
        appBar: AppBar(title: Text(d?.orderNo ?? l.ordersDetails)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          OrderFeedback(m),
          SbButton(
              label: l.authRetry,
              variant: SbButtonVariant.secondary,
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
            Text(d.customerName),
            Text(d.customerMobile),
            Text([
              d.address.line1,
              d.address.line2,
              d.address.landmark,
              d.address.city,
              d.address.state,
              d.address.pincode
            ].where((v) => v.isNotEmpty).join(', ')),
            SbButton(
                label: l.customersCall,
                onPressed: () async {
                  final ok =
                      await const CustomerDevice().dial(d.customerMobile);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.customersDialUnavailable)));
                  }
                }),
            Text(l.ordersItems, style: Theme.of(context).textTheme.titleMedium),
            for (final i in d.items)
              Text(
                  '${i.name} (${i.unitValue} ${i.unitType})\n${formatInr(int.parse(i.unitPricePaise))} × ${i.qty} = ${formatInr(int.parse(i.lineTotalPaise))}'),
            Text(l.checkoutSubtotal(formatInr(int.parse(d.subtotalPaise)))),
            Text(l.checkoutDelivery(d.deliveryChargePaise == '0'
                ? l.checkoutFree
                : formatInr(int.parse(d.deliveryChargePaise)))),
            Text(l.ordersDiscount(formatInr(int.parse(d.discountPaise)))),
            Text(l.checkoutTotal(formatInr(int.parse(d.totalPaise))),
                style: Theme.of(context).textTheme.titleLarge),
            Text(d.paymentMode == 'POD_CASH'
                ? l.checkoutCash
                : d.paymentMode == 'POD_UPI'
                    ? l.checkoutUpi
                    : l.navKhata),
            Text(d.paymentStatus == 'PAID' ? l.ordersPaid : l.ordersUnpaid),
            Text(d.source_ == 'APP'
                ? l.ordersApp
                : d.source_ == 'SUBSCRIPTION'
                    ? l.discoverySubscription
                    : l.ordersVendor),
            for (final reason in [d.rejectReason, d.cancelReason, d.failReason]
                .whereType<String>())
              Text(orderReason(l, reason)),
            Text(l.ordersTimeline,
                style: Theme.of(context).textTheme.titleMedium),
            for (final e in d.timeline)
              Text(
                  '${homeStatus(l, e.status)} · ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(e.at).toUtc().add(const Duration(hours: 5, minutes: 30)))} ${l.ordersIst}${e.reason == null ? '' : '\n${orderReason(l, e.reason!)}'}'),
            if (d.status == 'NEW') ...[
              SbButton(
                  label: l.ordersAccept,
                  onPressed: can ? () => m.act(d.id, 'ACCEPTED') : null),
              SbButton(
                  label: l.ordersReject,
                  variant: SbButtonVariant.destructive,
                  onPressed: can
                      ? () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => RejectOrderSheet(model: m, id: d.id))
                      : null)
            ],
            if (d.status == 'ACCEPTED')
              SbButton(
                  label: l.ordersPacked,
                  onPressed: can ? () => m.act(d.id, 'PREPARING') : null),
            if (['ACCEPTED', 'PREPARING'].contains(d.status))
              SbButton(
                  label: l.ordersStartDelivery,
                  onPressed:
                      can ? () => m.act(d.id, 'OUT_FOR_DELIVERY') : null),
          ],
        ])));
  }
}

class RejectOrderSheet extends StatefulWidget {
  const RejectOrderSheet({required this.model, required this.id, super.key});
  final VendorOrdersController model;
  final String id;
  @override
  State<RejectOrderSheet> createState() => _RejectOrderSheetState();
}

class _RejectOrderSheetState extends State<RejectOrderSheet> {
  String? reason;
  String text = '';
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
        child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(l.ordersReject,
                      style: Theme.of(context).textTheme.titleLarge),
                  DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.ordersReason),
                      items: [
                        'CUSTOMER_UNAVAILABLE',
                        'OUT_OF_STOCK',
                        'NOT_SERVICEABLE',
                        'CUSTOMER_REQUEST',
                        'OTHER'
                      ]
                          .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(orderReason(l, r),
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => reason = v)),
                  if (reason == 'OTHER')
                    TextField(
                        maxLength: 200,
                        minLines: 2,
                        maxLines: 4,
                        decoration:
                            InputDecoration(labelText: l.ordersReasonHelp),
                        onChanged: (v) => setState(() => text = v)),
                  SbButton(
                      label: l.ordersReject,
                      variant: SbButtonVariant.destructive,
                      onPressed: reason == null ||
                              reason == 'OTHER' && text.trim().length < 5
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.model.act(widget.id, 'REJECTED',
                                  reason: reason, text: text);
                            }),
                  SbButton(
                      label: l.productsCancel,
                      variant: SbButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context)),
                ]))));
  }
}
