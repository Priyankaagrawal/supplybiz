// S-V-15 / S-V-21 / T-076.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import 'vendor_subscriptions_controller.dart';

String subscriptionMoney(AppLocalizations l, BigInt amount) =>
    l.subMoney(subscriptionAmount(amount));

/// Indian grouping without converting integer paise through floating point.
String subscriptionAmount(BigInt amount) {
  var whole = (amount ~/ BigInt.from(100)).toString();
  final parts = <String>[];
  if (whole.length > 3) {
    parts.add(whole.substring(whole.length - 3));
    whole = whole.substring(0, whole.length - 3);
  }
  while (whole.length > 2 && parts.isNotEmpty) {
    parts.insert(0, whole.substring(whole.length - 2));
    whole = whole.substring(0, whole.length - 2);
  }
  parts.insert(0, whole);
  return '${parts.join(',')}.${(amount % BigInt.from(100)).toString().padLeft(2, '0')}';
}

String subscriptionStatus(AppLocalizations l, String status) =>
    switch (status) {
      'ACTIVE' => l.subActive,
      'PAUSED' => l.subPaused,
      'PENDING_APPROVAL' => l.subPending,
      'CANCELLED' => l.subCancelled,
      'REJECTED' => l.subRejected,
      'COMPLETED' => l.subCompleted,
      _ => l.customersAll
    };
String subscriptionAction(AppLocalizations l, String action) =>
    switch (action) {
      'APPROVE' => l.subApprove,
      'REJECT' => l.subReject,
      'PAUSE' => l.subPause,
      'RESUME' => l.subResume,
      'SKIP' => l.subSkip,
      'CANCEL' => l.subCancel,
      _ => l.subSave
    };
List<String> subscriptionDays(AppLocalizations l) =>
    [l.subMon, l.subTue, l.subWed, l.subThu, l.subFri, l.subSat, l.subSun];

class SubscriptionFeedback extends StatelessWidget {
  const SubscriptionFeedback(this.model, {super.key});
  final VendorSubscriptionsController model;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (model.busy) const SbSkeleton(lines: 2),
      if (model.failure != null)
        Semantics(liveRegion: true, child: Text(model.failure!.toMessage(l))),
      if (model.cached) Text(l.subOffline),
      if (model.settings != null && !model.settings!.canEditSubscriptions)
        Text(l.subPlanLocked),
      if (model.result != null)
        Semantics(
            liveRegion: true,
            child: Text(
                l.subEffective(subscriptionDate(model.result!.effectiveFrom)))),
      if (model.pending != null) ...[
        Text(l.subSaved),
        SbButton(
            label: model.retryExpired ? l.subReviewExpired : l.subRetry,
            onPressed: model.busy
                ? null
                : model.retryExpired
                    ? model.discardExpired
                    : model.retry)
      ],
      if (model.failure != null)
        SbButton(
            label: l.authRetry,
            variant: SbButtonVariant.secondary,
            onPressed: model.busy ? null : model.load),
    ]);
  }
}

/// Refresh on foreground; cached snapshots never authorize a new mutation.
class VendorSubscriptionsPage extends ConsumerStatefulWidget {
  const VendorSubscriptionsPage({this.id, super.key});
  final String? id;
  @override
  ConsumerState<VendorSubscriptionsPage> createState() =>
      _VendorSubscriptionsState();
}

class _VendorSubscriptionsState extends ConsumerState<VendorSubscriptionsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(vendorSubscriptionsProvider).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(vendorSubscriptionsProvider),
        l = context.l10n,
        row = widget.id == null ? null : m.find(widget.id!);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.id == null ? l.subTitle : l.routeSubscription)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SubscriptionFeedback(m),
                      if (widget.id == null) ...[
                        SbButton(
                            label: l.subSettings,
                            onPressed: () =>
                                context.push('/vendor/subscription-settings')),
                        SbButton(
                            label: l.subCreate,
                            onPressed:
                                m.canEdit ? () => _editor(context, m) : null),
                        TextField(
                            decoration:
                                InputDecoration(labelText: l.customersSearch),
                            onChanged: (v) => m.query(v, m.filter)),
                        DropdownButtonFormField<String>(
                            initialValue: m.filter,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.customersFilter),
                            items: [
                              for (final s in [
                                'ALL',
                                'ACTIVE',
                                'PAUSED',
                                'PENDING_APPROVAL',
                                'CANCELLED',
                                'REJECTED',
                                'COMPLETED'
                              ])
                                DropdownMenuItem(
                                    value: s,
                                    child: Text(subscriptionStatus(l, s)))
                            ],
                            onChanged: (s) {
                              if (s != null) m.query(m.search, s);
                            }),
                        if (m.ready && m.visible.isEmpty)
                          SbEmpty(message: l.subEmpty),
                        for (final s in m.visible)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(s.productName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge),
                                        Text(
                                            m.customerName(s.vendorCustomerId)),
                                        Text(subscriptionStatus(l, s.status)),
                                        Text(l.subDaily(subscriptionMoney(l,
                                            BigInt.parse(s.dailyAmountPaise)))),
                                        Text(l.subMonthly(
                                            subscriptionMoney(
                                                l,
                                                BigInt.parse(
                                                    s.monthlyEstimatePaise)),
                                            s.estimateMonth)),
                                        SbButton(
                                            label: l.customersView,
                                            onPressed: () =>
                                                VendorSubscriptionRoute(s.id)
                                                    .push<void>(context))
                                      ]))),
                        if (m.visible.length < m.filtered.length)
                          SbButton(label: l.customersMore, onPressed: m.more),
                      ] else if (row != null)
                        ..._detail(context, m, row)
                      else if (m.ready)
                        SbEmpty(message: l.networkNotFound),
                    ]))));
  }

  Future<void> _editor(BuildContext context, VendorSubscriptionsController m,
      {SubscriptionRecord? row}) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => VendorSubscriptionEditor(model: m, row: row)));
  }

  List<Widget> _detail(BuildContext context, VendorSubscriptionsController m,
      SubscriptionRecord r) {
    final l = context.l10n, live = ['ACTIVE', 'PAUSED'].contains(r.status);
    return [
      Text(r.productName, style: Theme.of(context).textTheme.headlineSmall),
      Text(m.customerName(r.vendorCustomerId)),
      Text(subscriptionStatus(l, r.status)),
      Text(l.subQuantityValue(r.qty, r.timeSlot)),
      Text([for (final day in r.weekdays) subscriptionDays(l)[day.toInt() - 1]]
          .join(', ')),
      Text(l.subDates(subscriptionDate(r.startDate),
          r.endDate == null ? l.subNoEnd : subscriptionDate(r.endDate!))),
      Text(l.subDaily(subscriptionMoney(l, BigInt.parse(r.dailyAmountPaise)))),
      Text(l.subMonthly(
          subscriptionMoney(l, BigInt.parse(r.monthlyEstimatePaise)),
          r.estimateMonth)),
      Text(l.subCutoff),
      if (live)
        SbButton(
            label: l.customersEdit,
            onPressed: m.canEdit ? () => _editor(context, m, row: r) : null),
      for (final action in [
        if (r.status == 'PENDING_APPROVAL') ...'APPROVE REJECT'.split(' '),
        if (live) ...['PAUSE', 'RESUME', 'SKIP', 'CANCEL']
      ])
        SbButton(
            label: subscriptionAction(l, action),
            onPressed: (['APPROVE', 'RESUME'].contains(action)
                    ? m.canEdit
                    : m.canReduce)
                ? () => _action(context, m, r, action)
                : null),
      for (final p in r.pauses)
        Text(l.subPausedDates(subscriptionDate(p.fromDate),
            p.toDate == null ? l.subNoEnd : subscriptionDate(p.toDate!))),
      for (final day in r.skips) Text(l.subSkippedDate(day)),
    ];
  }

  Future<void> _action(BuildContext context, VendorSubscriptionsController m,
      SubscriptionRecord row, String action) async {
    final l = context.l10n,
        businessDay = m.settings!.businessDate,
        form = GlobalKey<FormState>(),
        start = TextEditingController(
            text: subscriptionDate(m.settings!.businessDate)),
        end = TextEditingController(),
        reason = TextEditingController();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: Text(subscriptionAction(l, action)),
                content: SingleChildScrollView(
                    child: Form(
                        key: form,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(l.subCutoff),
                          if (action == 'CANCEL') Text(l.subCancelInfo),
                          if (action == 'SKIP' || action == 'PAUSE')
                            TextFormField(
                                controller: start,
                                decoration:
                                    InputDecoration(labelText: l.subFrom),
                                validator: (v) {
                                  final d = subscriptionParseDate(v ?? '');
                                  return d == null || d.isBefore(businessDay)
                                      ? l.subInvalid
                                      : null;
                                }),
                          if (action == 'PAUSE')
                            TextFormField(
                                controller: end,
                                decoration:
                                    InputDecoration(labelText: l.subEnd),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return null;
                                  final d = subscriptionParseDate(v),
                                      s = subscriptionParseDate(start.text);
                                  return d == null || s == null || d.isBefore(s)
                                      ? l.subInvalid
                                      : null;
                                }),
                          if (action == 'REJECT')
                            TextFormField(
                                controller: reason,
                                maxLength: 100,
                                decoration:
                                    InputDecoration(labelText: l.subReason),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? l.subInvalid
                                    : null)
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: Text(l.productsCancel)),
                  TextButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(dialog, true);
                        }
                      },
                      child: Text(l.customersConfirm))
                ]));
    final body = <String, dynamic>{
      'version': row.version,
      if (action == 'PAUSE') 'fromDate': start.text,
      if (action == 'PAUSE' && end.text.isNotEmpty) 'toDate': end.text,
      if (action == 'SKIP') 'date': start.text,
      if (action == 'REJECT') 'reason': reason.text.trim()
    };
    start.dispose();
    end.dispose();
    reason.dispose();
    if (confirmed == true &&
        mounted &&
        identical(m, ref.read(vendorSubscriptionsProvider)) &&
        m.canWrite) {
      await m.submit(action, body, id: row.id);
    }
  }
}

class VendorSubscriptionEditor extends StatefulWidget {
  const VendorSubscriptionEditor({required this.model, this.row, super.key});
  final VendorSubscriptionsController model;
  final SubscriptionRecord? row;
  @override
  State<VendorSubscriptionEditor> createState() => _SubscriptionEditorState();
}

class _SubscriptionEditorState extends State<VendorSubscriptionEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController qty, start, end;
  String? customer, product, slot;
  String customerQuery = '';
  String payment = 'CASH';
  Set<int> days = {1, 2, 3, 4, 5, 6, 7};
  bool submitted = false, invalid = false;
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    qty = TextEditingController(text: '${r?.qty ?? 1}');
    start = TextEditingController(
        text: subscriptionDate(r?.startDate ?? widget.model.tomorrow!));
    end = TextEditingController(
        text: r?.endDate == null ? '' : subscriptionDate(r!.endDate!));
    customer = r?.vendorCustomerId;
    product = r?.productId;
    slot = r?.timeSlot;
    payment = r?.paymentMethod ?? 'CASH';
    if (r != null) days = r.weekdays.map((n) => n.toInt()).toSet();
  }

  @override
  void dispose() {
    qty.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.model,
      builder: (context, _) {
        final m = widget.model,
            l = context.l10n,
            editing = widget.row != null,
            sku = m.products.where((p) => p.id == product).firstOrNull;
        final s = subscriptionParseDate(start.text),
            e = end.text.isEmpty ? null : subscriptionParseDate(end.text),
            quantity = int.tryParse(qty.text);
        final estimate =
            sku != null && s != null && quantity != null && quantity > 0
                ? subscriptionEstimate(
                    BigInt.from(
                        sku.subscriptionPricePaise ?? sku.sellingPricePaise),
                    quantity,
                    days,
                    s,
                    e,
                    s)
                : null;
        return Scaffold(
            appBar:
                AppBar(title: Text(editing ? l.customersEdit : l.subCreate)),
            body: SafeArea(
                child: Form(
                    key: form,
                    child:
                        ListView(padding: const EdgeInsets.all(16), children: [
                      SubscriptionFeedback(m),
                      if (!editing) ...[
                        TextField(
                            decoration:
                                InputDecoration(labelText: l.customersSearch),
                            onChanged: (v) => setState(
                                () => customerQuery = v.toLowerCase())),
                        DropdownButtonFormField<String>(
                            initialValue: customer,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.subCustomer),
                            items: [
                              for (final c in m.customers.where((c) =>
                                  c.status.value == 'ACTIVE' &&
                                  (c.id == customer ||
                                      '${c.name} ${c.mobile}'
                                          .toLowerCase()
                                          .contains(customerQuery))))
                                DropdownMenuItem(
                                    value: c.id, child: Text(c.name))
                            ],
                            onChanged: (v) => setState(() => customer = v),
                            validator: (v) => v == null ? l.subInvalid : null),
                        SbButton(
                            label: l.customersAdd,
                            onPressed: m.canEdit
                                ? () async {
                                    await const VendorCustomerNewRoute()
                                        .push<void>(context);
                                    await m.load();
                                    if (mounted) setState(() {});
                                  }
                                : null),
                        DropdownButtonFormField<String>(
                            initialValue: product,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.subProduct),
                            items: [
                              for (final p
                                  in m.products.where((p) => p.isActive))
                                DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                        '${p.name} (${p.unitValue} ${p.unitType.value}) — ${subscriptionMoney(l, BigInt.from(p.subscriptionPricePaise ?? p.sellingPricePaise))}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis))
                            ],
                            onChanged: (v) => setState(() => product = v),
                            validator: (v) => v == null ? l.subInvalid : null),
                      ] else
                        Text(widget.row!.productName),
                      TextFormField(
                          controller: qty,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l.subQty),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            return n == null || n < 1 || n > 2147483647
                                ? l.subInvalid
                                : null;
                          }),
                      Row(children: [
                        IconButton(
                            tooltip: l.subLess,
                            constraints: const BoxConstraints(
                                minWidth: 48, minHeight: 48),
                            onPressed:
                                m.canEdit && (int.tryParse(qty.text) ?? 0) > 1
                                    ? () => setState(() =>
                                        qty.text = '${int.parse(qty.text) - 1}')
                                    : null,
                            icon: const Icon(Icons.remove)),
                        IconButton(
                            tooltip: l.subMore,
                            constraints: const BoxConstraints(
                                minWidth: 48, minHeight: 48),
                            onPressed: m.canEdit &&
                                    (int.tryParse(qty.text) ?? 2147483647) <
                                        2147483647
                                ? () => setState(() =>
                                    qty.text = '${int.parse(qty.text) + 1}')
                                : null,
                            icon: const Icon(Icons.add)),
                      ]),
                      if (sku != null)
                        Text('${sku.unitValue} ${sku.unitType.value}'),
                      Wrap(spacing: 8, children: [
                        for (var d = 1; d <= 7; d++)
                          ConstrainedBox(
                              constraints: const BoxConstraints(
                                  minHeight: 48, minWidth: 48),
                              child: FilterChip(
                                  label: Text(subscriptionDays(l)[d - 1]),
                                  selected: days.contains(d),
                                  onSelected: (v) => setState(() {
                                        v ? days.add(d) : days.remove(d);
                                      })))
                      ]),
                      SbButton(
                          label: l.subDailyDays,
                          variant: SbButtonVariant.secondary,
                          onPressed: () =>
                              setState(() => days = {1, 2, 3, 4, 5, 6, 7})),
                      if (!editing) ...[
                        TextFormField(
                            controller: start,
                            decoration: InputDecoration(labelText: l.subStart),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final d = subscriptionParseDate(v ?? '');
                              return d == null || d.isBefore(m.tomorrow!)
                                  ? l.subInvalid
                                  : null;
                            }),
                        TextFormField(
                            controller: end,
                            decoration: InputDecoration(labelText: l.subEnd),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final d = subscriptionParseDate(v),
                                  s = subscriptionParseDate(start.text);
                              return d == null || s == null || d.isBefore(s)
                                  ? l.subInvalid
                                  : null;
                            }),
                      ],
                      DropdownButtonFormField<String>(
                          initialValue: m.slots.contains(slot) ? slot : null,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l.subSlot),
                          items: [
                            for (final value in m.slots)
                              DropdownMenuItem(value: value, child: Text(value))
                          ],
                          onChanged: (v) => setState(() => slot = v),
                          validator: (v) => v == null ? l.subInvalid : null),
                      if (!editing)
                        DropdownButtonFormField<String>(
                            initialValue: payment,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.subPayment),
                            items: [
                              for (final value in [
                                'CASH',
                                'UPI',
                                'BANK',
                                'WALLET'
                              ])
                                DropdownMenuItem(
                                    value: value,
                                    child: Text(switch (value) {
                                      'UPI' => l.customersUpi,
                                      'BANK' => l.customersBank,
                                      'WALLET' => l.customersWallet,
                                      _ => l.customersCash
                                    }))
                            ],
                            onChanged: (v) => setState(() => payment = v!)),
                      if (estimate != null) ...[
                        Text(l.subDaily(subscriptionMoney(l, estimate.daily))),
                        Text(l.subMonthly(
                            subscriptionMoney(l, estimate.monthly),
                            subscriptionDate(s!).substring(0, 7)))
                      ],
                      Text(l.subCutoff),
                      Text(l.subPostpaid),
                      if (submitted && (days.isEmpty || invalid))
                        Semantics(liveRegion: true, child: Text(l.subInvalid)),
                      SbButton(
                          label: l.subSave,
                          onPressed: m.canEdit
                              ? () async {
                                  setState(() => submitted = true);
                                  if (!form.currentState!.validate() ||
                                      days.isEmpty) {
                                    setState(() => invalid = true);
                                    return;
                                  }
                                  setState(() => invalid = false);
                                  final body = <String, dynamic>{
                                    'qty': int.parse(qty.text),
                                    'weekdays': days.toList()..sort(),
                                    'timeSlot': slot,
                                    if (editing) 'version': widget.row!.version,
                                    if (!editing) ...{
                                      'vendorCustomerId': customer,
                                      'productId': product,
                                      'startDate': start.text,
                                      if (end.text.isNotEmpty)
                                        'endDate': end.text,
                                      'paymentMethod': payment
                                    }
                                  };
                                  await m.submit(
                                      editing ? 'EDIT' : 'CREATE', body,
                                      id: widget.row?.id);
                                  if (context.mounted &&
                                      m.result != null &&
                                      m.pending == null) {
                                    Navigator.pop(context);
                                  }
                                }
                              : null),
                    ]))));
      });
}

class VendorSubscriptionSettingsPage extends ConsumerWidget {
  const VendorSubscriptionSettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(vendorSubscriptionsProvider),
        l = context.l10n,
        s = m.settings;
    Future<void> toggle(String field, bool value) async {
      final ok = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                  title: Text(l.subConfirmSettings),
                  content: Text(l.subSettingsEffect),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialog, false),
                        child: Text(l.productsCancel)),
                    TextButton(
                        onPressed: () => Navigator.pop(dialog, true),
                        child: Text(l.customersConfirm))
                  ]));
      if (ok == true &&
          context.mounted &&
          identical(m, ref.read(vendorSubscriptionsProvider)) &&
          m.canWrite) {
        await m.submit('SETTINGS', {'version': s!.version, field: value});
      }
    }

    return Scaffold(
        appBar: AppBar(title: Text(l.subSettings)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SubscriptionFeedback(m),
                      if (s != null) ...[
                        Text(l.subSummary(
                            s.summary.totalSubscriptions,
                            s.summary.active,
                            s.summary.paused,
                            s.summary.pendingApproval,
                            s.summary.subscriptionCustomers)),
                        SwitchListTile(
                            title: Text(l.subAutoAccept),
                            subtitle: Text(l.subBusinessGuidance),
                            value: s.autoAcceptSubscriptions,
                            onChanged: m.canWrite &&
                                    (s.canAutoAccept ||
                                        s.autoAcceptSubscriptions)
                                ? (v) => toggle('autoAcceptSubscriptions', v)
                                : null),
                        Text(s.effectiveAutoAcceptSubscriptions
                            ? l.subAutoEffective
                            : l.subAutoInactive),
                        SwitchListTile(
                            title: Text(l.subAvailable),
                            value: s.deliveryAvailable,
                            onChanged: m.canWrite &&
                                    (s.canEditSubscriptions ||
                                        s.deliveryAvailable)
                                ? (v) => toggle('deliveryAvailable', v)
                                : null),
                        SwitchListTile(
                            title: Text(l.subPauseAll),
                            value: s.pauseAllSubscriptions,
                            onChanged: m.canWrite &&
                                    (s.canEditSubscriptions ||
                                        !s.pauseAllSubscriptions)
                                ? (v) => toggle('pauseAllSubscriptions', v)
                                : null),
                        SubscriptionLimitsForm(
                            key: ValueKey(s.version), model: m),
                      ]
                    ]))));
  }
}

class SubscriptionLimitsForm extends StatefulWidget {
  const SubscriptionLimitsForm({required this.model, super.key});
  final VendorSubscriptionsController model;
  @override
  State<SubscriptionLimitsForm> createState() => _LimitsState();
}

class _LimitsState extends State<SubscriptionLimitsForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController orders, milk, start, end;
  @override
  void initState() {
    super.initState();
    final s = widget.model.settings!;
    orders = TextEditingController(text: s.maxDailyOrders?.toString() ?? '');
    milk = TextEditingController(text: s.dailyMilkCapacityLitres ?? '');
    start = TextEditingController(text: s.deliveryStartTime ?? '');
    end = TextEditingController(text: s.deliveryEndTime ?? '');
  }

  @override
  void dispose() {
    orders.dispose();
    milk.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model, l = context.l10n;
    String? time(String? v) => v != null &&
            v.isNotEmpty &&
            !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v)
        ? l.subInvalid
        : null;
    return Form(
        key: form,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.subLimitsInfo),
          TextFormField(
              controller: orders,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.subOrderCap),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = int.tryParse(v);
                return n == null || n <= 0 || n > 2147483647
                    ? l.subInvalid
                    : null;
              }),
          TextFormField(
              controller: milk,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.subMilkCap),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!RegExp(r'^(0|[1-9]\d{0,6})(\.\d{1,3})?$').hasMatch(v)) {
                  return l.subInvalid;
                }
                final parts = v.split('.'),
                    ml = BigInt.parse(parts[0]) * BigInt.from(1000) +
                        BigInt.parse((parts.length == 1 ? '' : parts[1])
                            .padRight(3, '0'));
                return ml <= BigInt.zero || ml > BigInt.from(2147483647)
                    ? l.subInvalid
                    : null;
              }),
          TextFormField(
              controller: start,
              decoration: InputDecoration(labelText: l.subWindowStart),
              validator: time),
          TextFormField(
              controller: end,
              decoration: InputDecoration(labelText: l.subWindowEnd),
              validator: (v) =>
                  time(v) ??
                  (start.text.isEmpty != end.text.isEmpty ||
                          start.text.isNotEmpty && start.text == end.text
                      ? l.subInvalid
                      : null)),
          SbButton(
              label: l.subSave,
              onPressed: m.canEdit
                  ? () async {
                      if (!form.currentState!.validate()) return;
                      final s = m.settings!,
                          body = <String, dynamic>{'version': s.version};
                      if (orders.text != (s.maxDailyOrders?.toString() ?? '')) {
                        if (orders.text.isEmpty) {
                          body['clearMaxDailyOrders'] = true;
                        } else {
                          body['maxDailyOrders'] = int.parse(orders.text);
                        }
                      }
                      if (milk.text != (s.dailyMilkCapacityLitres ?? '')) {
                        if (milk.text.isEmpty) {
                          body['clearDailyMilkCapacity'] = true;
                        } else {
                          body['dailyMilkCapacityLitres'] = milk.text;
                        }
                      }
                      if (start.text != (s.deliveryStartTime ?? '') ||
                          end.text != (s.deliveryEndTime ?? '')) {
                        if (start.text.isEmpty) {
                          body['clearDeliveryWindow'] = true;
                        } else {
                          body['deliveryStartTime'] = start.text;
                          body['deliveryEndTime'] = end.text;
                        }
                      }
                      if (body.length > 1) await m.submit('SETTINGS', body);
                    }
                  : null),
        ]));
  }
}
