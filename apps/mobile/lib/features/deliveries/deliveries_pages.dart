// S-V-16 Deliveries / S-V-34 Sync queue, T-050.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/storage/customer_device.dart';
import '../auth/session_controller.dart';
import '../home/home_page.dart' show homeStatus;
import '../orders/orders_pages.dart' show orderFilterDate, orderFailure;
import 'deliveries_controller.dart';

/// Foreground sync lives above navigation so leaving Deliveries does not stop it.
/// API reachability is tested by sending the durable action itself.
class DeliverySyncHost extends ConsumerStatefulWidget {
  const DeliverySyncHost({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<DeliverySyncHost> createState() => _DeliverySyncHostState();
}

class _DeliverySyncHostState extends ConsumerState<DeliverySyncHost>
    with WidgetsBindingObserver {
  Timer? timer;
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 2), (_) => sync());
  }

  void sync() {
    if (!foreground) return;
    final user = ref.read(sessionProvider).user;
    if (foreground && user?.activeRole?.value == 'VENDOR') {
      final m = ref.read(deliveriesProvider);
      if (!m.busy) unawaited(m.flush());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) sync();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class DeliveriesPage extends ConsumerStatefulWidget {
  const DeliveriesPage({this.queueOnly = false, super.key});
  final bool queueOnly;
  @override
  ConsumerState<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends ConsumerState<DeliveriesPage> {
  DeliveriesController? initialized;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(deliveriesProvider), l = context.l10n;
    if (initialized != m) {
      initialized = m;
      Future.microtask(() async {
        await m.flush();
        if (!widget.queueOnly) await m.load();
      });
    }
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.queueOnly ? l.deliveryQueue : l.deliveryTitle)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (m.busy) const SbSkeleton(),
                      if (m.failure != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(orderFailure(m.failure!, l))),
                      if (m.stale && m.cache.isNotEmpty) Text(l.deliveryCached),
                      SbButton(
                          label: l.authRetry,
                          onPressed: m.busy ? null : m.load),
                      if (!widget.queueOnly) ...[
                        SbButton(
                            label: '${l.deliveryQueue} (${m.queue.length})',
                            onPressed: () =>
                                context.push('/vendor/sync-queue')),
                        TextFormField(
                            key: ValueKey(m.date),
                            initialValue: m.date,
                            enabled: !m.busy,
                            decoration:
                                InputDecoration(labelText: l.ordersDate),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (s) => orderFilterDate(s ?? '') == null
                                ? l.ordersInvalidDate
                                : null,
                            onFieldSubmitted: (s) {
                              if (orderFilterDate(s) != null) m.load(day: s);
                            }),
                        Wrap(spacing: 8, children: [
                          for (final tab in [
                            'ALL',
                            'PENDING',
                            'PREPARING',
                            'OUT_FOR_DELIVERY',
                            'DELIVERED',
                            'FAILED'
                          ])
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minHeight: 48),
                                    child: ChoiceChip(
                                        label: Text(
                                            '${tab == 'ALL' ? l.customersAll : tab == 'PENDING' ? l.deliveryPending : homeStatus(l, tab)} (${m.count(tab)})'),
                                        selected: m.filter == tab,
                                        onSelected: (_) => m.select(tab)))),
                        ]),
                        if (m.restored && m.visible.isEmpty && !m.busy)
                          SbEmpty(message: l.deliveryEmpty),
                        for (final row in m.visible) _card(context, m, row),
                      ] else ...[
                        Text(l.deliveryQueueHelp),
                        SbButton(
                            label: l.deliveryRetry,
                            onPressed:
                                m.busy ? null : () => m.flush(retry: true)),
                        if (m.queue.isEmpty)
                          SbEmpty(message: l.deliveryQueueEmpty),
                        for (final a in m.queue)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(a.orderNo),
                                        Text(homeStatus(
                                            l, a.body['to'] as String)),
                                        Text(a.rejected
                                            ? l.deliveryRejected
                                            : a.retryable
                                                ? l.deliveryRetryNeeded
                                                : l.deliveryPendingSync),
                                        if (a.rejected)
                                          Text(l.deliveryRollback),
                                        if (m.canDiscard(a))
                                          SbButton(
                                              label: l.deliveryDiscard,
                                              onPressed: m.busy
                                                  ? null
                                                  : () async {
                                                      final yes = await showDialog<
                                                              bool>(
                                                          context: context,
                                                          builder: (ctx) =>
                                                              AlertDialog(
                                                                  title: Text(l
                                                                      .deliveryDiscard),
                                                                  content: Text(
                                                                      l.deliveryDiscardConfirm),
                                                                  actions: [
                                                                    TextButton(
                                                                        onPressed: () => Navigator.pop(
                                                                            ctx,
                                                                            false),
                                                                        child: Text(
                                                                            l.deliveryCancel)),
                                                                    SbButton(
                                                                        label: l
                                                                            .deliveryDiscard,
                                                                        onPressed: () => Navigator.pop(
                                                                            ctx,
                                                                            true)),
                                                                  ]));
                                                      if (yes == true) {
                                                        await m.discard(a);
                                                      }
                                                    }),
                                      ]))),
                      ],
                    ]))));
  }

  Widget _card(BuildContext context, DeliveriesController m, OrderDetail row) {
    final l = context.l10n, status = m.status(row), can = m.canAct(row.id);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(row.orderNo,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('${row.timeSlot} · ${homeStatus(l, status)}'),
                  if (m.pending(row.id))
                    Semantics(
                        liveRegion: true, child: Text(l.deliveryPendingSync)),
                  Text(row.customerName),
                  Text([
                    row.address.line1,
                    row.address.line2,
                    row.address.landmark,
                    row.address.city,
                    row.address.state,
                    row.address.pincode
                  ].where((s) => s.isNotEmpty).join(', ')),
                  for (final i in row.items)
                    Text('${i.name} (${i.unitValue} ${i.unitType}) × ${i.qty}'),
                  Text(formatInr(int.parse(row.totalPaise))),
                  SbButton(
                      label: l.customersCall,
                      onPressed: () async {
                        final ok = await const CustomerDevice()
                            .dial(row.customerMobile);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(l.customersDialUnavailable)));
                        }
                      }),
                  if (status == 'ACCEPTED')
                    SbButton(
                        label: l.ordersPacked,
                        onPressed:
                            can ? () => m.enqueue(row, 'PREPARING') : null),
                  if (['ACCEPTED', 'PREPARING'].contains(status))
                    SbButton(
                        label: l.ordersStartDelivery,
                        onPressed: can
                            ? () => m.enqueue(row, 'OUT_FOR_DELIVERY')
                            : null),
                  if (status == 'OUT_FOR_DELIVERY') ...[
                    SbButton(
                        label: l.deliveryDelivered,
                        onPressed:
                            can ? () => _action(context, m, row, false) : null),
                    SbButton(
                        label: l.deliveryFailed,
                        onPressed:
                            can ? () => _action(context, m, row, true) : null),
                  ],
                ])));
  }

  Future<void> _action(BuildContext context, DeliveriesController m,
      OrderDetail row, bool failed) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (_) => DeliveryActionSheet(row: row, failed: failed));
    if (result != null) {
      await m.enqueue(row, failed ? 'FAILED' : 'DELIVERED',
          reason: result['reason'] as String?, payment: failed ? null : result);
    }
  }
}

class DeliveryActionSheet extends StatefulWidget {
  const DeliveryActionSheet(
      {required this.row, required this.failed, super.key});
  final OrderDetail row;
  final bool failed;
  @override
  State<DeliveryActionSheet> createState() => _DeliveryActionSheetState();
}

class _DeliveryActionSheetState extends State<DeliveryActionSheet> {
  final form = GlobalKey<FormState>();
  bool collected = false;
  String method = 'CASH', reason = '', amount = '';
  String? paise(String input) {
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(input.trim())) return null;
    final parts = input.trim().split('.');
    final value = BigInt.parse(parts.first) * BigInt.from(100) +
        BigInt.parse(parts.length == 1 ? '0' : parts.last.padRight(2, '0'));
    return value > BigInt.zero && value <= BigInt.parse('9223372036854775807')
        ? '$value'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
        child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
            child: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              widget.failed
                                  ? l.deliveryFailed
                                  : l.deliveryDelivered,
                              style: Theme.of(context).textTheme.titleLarge),
                          if (widget.failed)
                            TextFormField(
                                maxLength: 200,
                                decoration: InputDecoration(
                                    labelText: l.deliveryReason),
                                onChanged: (v) => reason = v.trim(),
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? l.deliveryReasonRequired
                                    : null)
                          else ...[
                            SwitchListTile(
                                title: Text(l.deliveryCollected),
                                value: collected,
                                onChanged: (v) =>
                                    setState(() => collected = v)),
                            if (collected) ...[
                              DropdownButtonFormField<String>(
                                  initialValue: method,
                                  decoration: InputDecoration(
                                      labelText: l.deliveryMethod),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'CASH',
                                        child: Text(l.checkoutCash)),
                                    DropdownMenuItem(
                                        value: 'UPI',
                                        child: Text(l.checkoutUpi))
                                  ],
                                  onChanged: (v) => method = v ?? 'CASH'),
                              TextFormField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                      labelText: l.deliveryAmount),
                                  maxLength: 22,
                                  onChanged: (v) => amount = v,
                                  validator: (v) => paise(v ?? '') == null
                                      ? l.deliveryAmountInvalid
                                      : null),
                            ],
                          ],
                          SbButton(
                              label: l.customersConfirm,
                              onPressed: () {
                                if (!form.currentState!.validate()) return;
                                Navigator.pop(
                                    context,
                                    widget.failed
                                        ? {'reason': reason}
                                        : {
                                            'collected': collected,
                                            if (collected) 'method': method,
                                            if (collected)
                                              'amountPaise': paise(amount),
                                          });
                              }),
                        ])))));
  }
}
