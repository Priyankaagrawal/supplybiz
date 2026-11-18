// T-078 / S-C-09,10,15,16: real customer APIs; no funds taken at setup.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import 'customer_subscriptions_controller.dart';
import 'vendor_subscriptions_controller.dart'
    show subscriptionDate, subscriptionParseDate, subscriptionEstimate;
import 'vendor_subscriptions_pages.dart'
    show
        subscriptionMoney,
        subscriptionStatus,
        subscriptionDays,
        subscriptionAction;

class CustomerSubscriptionFeedback extends StatelessWidget {
  const CustomerSubscriptionFeedback(this.model, {super.key});
  final CustomerSubscriptionsController model;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = switch (model.failure?.code) {
      'PAST_CUTOFF' => l.customerSubCutoffError,
      'CUSTOMER_LINK_REQUIRED' => l.customerSubLink,
      'PLAN_FEATURE_LOCKED' => l.subPlanLocked,
      _ => model.failure?.toMessage(l),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (model.busy) const SbSkeleton(lines: 2),
      if (error != null) Semantics(liveRegion: true, child: Text(error)),
      if (model.stale) Text(l.subOffline),
      if (model.result != null)
        Semantics(
            liveRegion: true,
            child: Text(
                '${subscriptionStatus(l, model.result!.status)} · ${l.subEffective(subscriptionDate(model.result!.effectiveFrom))}')),
      if (model.pending != null) ...[
        Text(l.subSaved),
        SbButton(label: l.subRetry, onPressed: model.busy ? null : model.retry)
      ],
    ]);
  }
}

class CustomerSubscriptionsPage extends ConsumerStatefulWidget {
  const CustomerSubscriptionsPage({this.id, super.key});
  final String? id;
  @override
  ConsumerState<CustomerSubscriptionsPage> createState() =>
      _CustomerSubscriptionsState();
}

class _CustomerSubscriptionsState
    extends ConsumerState<CustomerSubscriptionsPage>
    with WidgetsBindingObserver {
  CustomerSubscriptionsController? initialized;
  final month = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    month.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      ref.read(customerSubscriptionsProvider).load(id: widget.id);
    }
  }

  @override
  void didUpdateWidget(CustomerSubscriptionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      Future.microtask(
          () => ref.read(customerSubscriptionsProvider).load(id: widget.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(customerSubscriptionsProvider), l = context.l10n;
    if (initialized != m) {
      initialized = m;
      Future.microtask(() => m.load(id: widget.id));
    }
    final row = widget.id == null ? null : m.find(widget.id!);
    if (month.text.isEmpty && m.businessDate != null) {
      month.text = subscriptionDate(m.businessDate!).substring(0, 7);
    }
    return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.id == null ? l.customerSubMine : l.routeSubscription)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: () => m.load(id: widget.id),
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      CustomerSubscriptionFeedback(m),
                      SbButton(
                          label: l.authRetry,
                          onPressed:
                              m.busy ? null : () => m.load(id: widget.id)),
                      if (widget.id == null) ...[
                        SbButton(
                            label: l.customerSubPlans,
                            onPressed: () => const CustomerDiscoveryRoute()
                                .push<void>(context)),
                        if (m.ready && m.rows.isEmpty)
                          SbEmpty(message: l.subEmpty),
                        for (final r in m.visible)
                          Card(
                              child: ListTile(
                                  minVerticalPadding: 16,
                                  title: Text(r.productName),
                                  subtitle: Text(
                                      '${subscriptionStatus(l, r.status)} · ${l.subQuantityValue(r.qty, r.timeSlot)}'),
                                  onTap: () => CustomerSubscriptionRoute(r.id)
                                      .push<void>(context))),
                        if (m.visible.length < m.rows.length)
                          SbButton(label: l.customerSubMore, onPressed: m.more),
                      ] else if (row == null && !m.busy)
                        Text(l.networkNotFound)
                      else if (row != null) ...[
                        Text(row.productName,
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(subscriptionStatus(l, row.status)),
                        Text(l.subQuantityValue(row.qty, row.timeSlot)),
                        Text([
                          for (final d in row.weekdays)
                            subscriptionDays(l)[d.toInt() - 1]
                        ].join(', ')),
                        Text(l.subDates(
                            subscriptionDate(row.startDate),
                            row.endDate == null
                                ? l.subNoEnd
                                : subscriptionDate(row.endDate!))),
                        Text(l
                            .subEffective(subscriptionDate(row.effectiveFrom))),
                        Text(l.subDaily(subscriptionMoney(
                            l, BigInt.parse(row.dailyAmountPaise)))),
                        Text(l.subMonthly(
                            subscriptionMoney(
                                l, BigInt.parse(row.monthlyEstimatePaise)),
                            row.estimateMonth)),
                        Text(l.subPostpaid),
                        Text(l.subCutoff),
                        if (['ACTIVE', 'PAUSED'].contains(row.status)) ...[
                          SbButton(
                              label: l.customersEdit,
                              onPressed: m.canWrite
                                  ? () async {
                                      await m.prepare(row.vendorId);
                                      if (context.mounted && m.canCreate) {
                                        await Navigator.of(context).push<void>(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    CustomerSubscriptionEditor(
                                                        model: m, row: row)));
                                      }
                                    }
                                  : null),
                          for (final action in [
                            'PAUSE',
                            'RESUME',
                            'SKIP',
                            'CANCEL'
                          ])
                            SbButton(
                                label: subscriptionAction(l, action),
                                onPressed: m.canWrite
                                    ? () => _action(m, row, action)
                                    : null),
                        ],
                        for (final p in row.pauses)
                          Text(l.subPausedDates(
                              subscriptionDate(p.fromDate),
                              p.toDate == null
                                  ? l.subNoEnd
                                  : subscriptionDate(p.toDate!))),
                        for (final d in row.skips) Text(l.subSkippedDate(d)),
                        Text(l.customerSubStatement,
                            style: Theme.of(context).textTheme.titleLarge),
                        TextField(
                            controller: month,
                            decoration:
                                InputDecoration(labelText: l.customerSubMonth),
                            onChanged: (_) => setState(() {})),
                        SbButton(
                            label: l.customerSubStatement,
                            onPressed: !m.busy &&
                                    RegExp(r'^[0-9]{4}-(0[1-9]|1[0-2])$')
                                        .hasMatch(month.text) &&
                                    !month.text.startsWith('0000')
                                ? () => m.readStatement(row.id, month.text)
                                : null),
                        if (m.statement?.subscriptionId == row.id &&
                            m.statement?.month == month.text)
                          ..._statement(context, m),
                      ],
                    ]))));
  }

  List<Widget> _statement(
      BuildContext context, CustomerSubscriptionsController m) {
    final l = context.l10n, s = m.statement!, ledger = s.ledger;
    return [
      Text('${l.customerSubQuantity}: ${s.deliveredQty}'),
      Text(
          '${l.customerSubAmount}: ${subscriptionMoney(l, BigInt.parse(s.deliveredAmountPaise))}'),
      Text(l.customerSubDelivered),
      if (s.items.isEmpty) Text(l.customerSubEmptyStatement),
      for (final d in s.items)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subscriptionDate(d.deliveryDate)),
                      Text(d.productName),
                      Text(l.subQuantityValue(d.qty, '')),
                      Text(subscriptionMoney(l, BigInt.parse(d.amountPaise))),
                      Text(d.paymentStatus == 'PAID'
                          ? l.ordersPaid
                          : l.ordersUnpaid)
                    ]))),
      if (s.items.length < s.total)
        SbButton(
            label: l.customerSubMore,
            onPressed: m.busy
                ? null
                : () => m.readStatement(s.subscriptionId, s.month, more: true)),
      Text(l.customerSubLedger),
      for (final pair in [
        (l.customerSubOpening, ledger.openingDuePaise),
        (l.customerSubPaid, ledger.monthPaidPaise),
        (l.customerSubClosing, ledger.closingDuePaise),
        (l.customerSubCurrent, ledger.duePaise)
      ])
        Text('${pair.$1}: ${subscriptionMoney(l, BigInt.parse(pair.$2))}'),
    ];
  }

  Future<void> _action(CustomerSubscriptionsController m,
      SubscriptionRecord row, String action) async {
    final l = context.l10n,
        form = GlobalKey<FormState>(),
        start = TextEditingController(
            text:
                subscriptionDate(m.businessDate!.add(const Duration(days: 1)))),
        end = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(subscriptionAction(l, action)),
                content: SingleChildScrollView(
                    child: Form(
                        key: form,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(l.subCutoff),
                          if (action == 'CANCEL') Text(l.subCancelInfo),
                          if (action == 'PAUSE' || action == 'SKIP')
                            TextFormField(
                                controller: start,
                                decoration:
                                    InputDecoration(labelText: l.subFrom),
                                validator: (v) =>
                                    subscriptionParseDate(v ?? '') == null
                                        ? l.subInvalid
                                        : null),
                          if (action == 'PAUSE')
                            TextFormField(
                                controller: end,
                                decoration:
                                    InputDecoration(labelText: l.subEnd),
                                validator: (v) => v == null || v.isEmpty
                                    ? null
                                    : subscriptionParseDate(v) == null ||
                                            v.compareTo(start.text) < 0
                                        ? l.subInvalid
                                        : null)
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.productsCancel)),
                  TextButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      child: Text(l.customersConfirm))
                ]));
    final body = <String, dynamic>{
      'version': row.version,
      if (action == 'SKIP') 'date': start.text,
      if (action == 'PAUSE') 'fromDate': start.text,
      if (action == 'PAUSE' && end.text.isNotEmpty) 'toDate': end.text
    };
    start.dispose();
    end.dispose();
    if (ok == true &&
        mounted &&
        identical(m, ref.read(customerSubscriptionsProvider)) &&
        m.canWrite) {
      await m.submit(action, body, id: row.id);
    }
  }
}

class CustomerSubscriptionPlansPage extends ConsumerStatefulWidget {
  const CustomerSubscriptionPlansPage({required this.vendorId, super.key});
  final String vendorId;
  @override
  ConsumerState<CustomerSubscriptionPlansPage> createState() => _PlansState();
}

class _PlansState extends ConsumerState<CustomerSubscriptionPlansPage> {
  CustomerSubscriptionsController? initialized;
  SubscriptionPlan? selected;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(customerSubscriptionsProvider), l = context.l10n;
    if (initialized != m) {
      initialized = m;
      selected = null;
      Future.microtask(() async {
        await m.load();
        await m.prepare(widget.vendorId);
      });
    }
    return Scaffold(
        appBar: AppBar(title: Text(l.customerSubPlans)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          CustomerSubscriptionFeedback(m),
          SbButton(
              label: l.authRetry,
              onPressed: m.busy
                  ? null
                  : () async {
                      await m.load();
                      await m.prepare(widget.vendorId);
                    }),
          SbButton(
              label: l.customerSubAddress,
              onPressed: () async {
                await const CustomerAddressesRoute().push<void>(context);
                await m.prepare(widget.vendorId);
                if (mounted) setState(() => selected = null);
              }),
          if (m.addresses.isNotEmpty)
            DropdownButtonFormField<String>(
                key: ValueKey(m.addressId),
                initialValue: m.addressId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.customerSubAddress),
                items: [
                  for (final a in m.addresses)
                    DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.label}: ${a.line1}',
                            maxLines: 1, overflow: TextOverflow.ellipsis))
                ],
                onChanged: m.busy || m.pending != null
                    ? null
                    : (id) async {
                        setState(() => selected = null);
                        await m.prepare(widget.vendorId, address: id);
                      }),
          if (m.plans != null) ...[
            if (m.plans!.freeDelivery) Text(l.customerSubFree),
            Text(l.customerSubFeatures),
            Text(l.subPostpaid),
            if (m.plans!.items.isEmpty) SbEmpty(message: l.discoveryNoProducts),
            RadioGroup<String>(
                groupValue: selected == null
                    ? null
                    : '${selected!.productId}:${selected!.kind}',
                onChanged: (value) {
                  if (m.canCreate) {
                    setState(() => selected = m.plans!.items
                        .where((p) => '${p.productId}:${p.kind}' == value)
                        .firstOrNull);
                  }
                },
                child: Column(children: [
                  for (final p in m.plans!.items)
                    Card(
                        child: RadioListTile<String>(
                            value: '${p.productId}:${p.kind}',
                            enabled: m.canCreate,
                            title: Text(
                                '${p.productName} · ${p.kind == 'CUSTOM' ? l.customerSubCustom : p.kind.replaceAll('_ML_DAILY', ' ml')}'),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.subDaily(subscriptionMoney(
                                      l, BigInt.parse(p.dailyAmountPaise)))),
                                  Text(l.subMonthly(
                                      subscriptionMoney(l,
                                          BigInt.parse(p.monthlyEstimatePaise)),
                                      m.plans!.estimateMonth)),
                                  if (p.mostPopular == true)
                                    Text(l.customerSubPopular)
                                ]))),
                ])),
          ],
          SbButton(
              label: l.notificationsContinue,
              onPressed: m.canCreate && selected != null
                  ? () => Navigator.of(context).push<void>(MaterialPageRoute(
                      builder: (_) =>
                          CustomerSubscriptionEditor(model: m, plan: selected)))
                  : null),
        ])));
  }
}

class CustomerSubscriptionEditor extends ConsumerStatefulWidget {
  const CustomerSubscriptionEditor(
      {required this.model, this.plan, this.row, super.key});
  final CustomerSubscriptionsController model;
  final SubscriptionPlan? plan;
  final SubscriptionRecord? row;
  @override
  ConsumerState<CustomerSubscriptionEditor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<CustomerSubscriptionEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController qty, start, end;
  String? slot, product;
  String payment = 'CASH';
  Set<int> days = {1, 2, 3, 4, 5, 6, 7};
  @override
  void initState() {
    super.initState();
    final r = widget.row, m = widget.model;
    qty = TextEditingController(text: '${r?.qty ?? widget.plan!.qty}');
    start = TextEditingController(
        text: subscriptionDate(r?.startDate ?? m.plans!.earliestStartDate));
    end = TextEditingController();
    slot = r?.timeSlot ?? m.plans!.timeSlots.firstOrNull;
    product = r?.productId ?? widget.plan!.productId;
    if (r != null) days = r.weekdays.map((d) => d.toInt()).toSet();
  }

  @override
  void dispose() {
    qty.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(customerSubscriptionsProvider),
        m = widget.model,
        l = context.l10n,
        r = widget.row;
    final validModel = identical(current, m),
        plan = m.plans?.items
            .where((p) => p.productId == product && p.kind == 'CUSTOM')
            .firstOrNull;
    final quantity = int.tryParse(qty.text),
        s = subscriptionParseDate(start.text),
        e = end.text.isEmpty ? null : subscriptionParseDate(end.text);
    final estimate =
        quantity != null && quantity > 0 && s != null && plan != null
            ? subscriptionEstimate(
                BigInt.parse(plan.dailyAmountPaise), quantity, days, s, e, s)
            : null;
    return Scaffold(
        appBar: AppBar(title: Text(r == null ? l.subCreate : l.customersEdit)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          CustomerSubscriptionFeedback(m),
          Form(
              key: form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (r == null && widget.plan?.kind == 'CUSTOM')
                      DropdownButtonFormField<String>(
                          initialValue: product,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l.subProduct),
                          items: [
                            for (final p in m.plans!.items
                                .where((p) => p.kind == 'CUSTOM'))
                              DropdownMenuItem(
                                  value: p.productId,
                                  child: Text(p.productName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis))
                          ],
                          onChanged: (v) => setState(() => product = v))
                    else
                      Text(r?.productName ?? widget.plan!.productName),
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
                    Wrap(spacing: 8, children: [
                      for (var d = 1; d <= 7; d++)
                        ConstrainedBox(
                            constraints: const BoxConstraints(
                                minWidth: 48, minHeight: 48),
                            child: FilterChip(
                                label: Text(subscriptionDays(l)[d - 1]),
                                selected: days.contains(d),
                                onSelected: (v) => setState(() {
                                      v ? days.add(d) : days.remove(d);
                                    })))
                    ]),
                    if (r == null) ...[
                      TextFormField(
                          controller: start,
                          decoration: InputDecoration(labelText: l.subStart),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final d = subscriptionParseDate(v ?? '');
                            return d == null ||
                                    d.isBefore(m.plans!.earliestStartDate)
                                ? l.subInvalid
                                : null;
                          }),
                      TextFormField(
                          controller: end,
                          decoration: InputDecoration(labelText: l.subEnd),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v == null || v.isEmpty
                              ? null
                              : subscriptionParseDate(v) == null ||
                                      s == null ||
                                      subscriptionParseDate(v)!.isBefore(s)
                                  ? l.subInvalid
                                  : null),
                      if (!m.upiAvailable) Text(l.customerSubCashOnly),
                      DropdownButtonFormField<String>(
                          initialValue: payment,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l.subPayment),
                          items: [
                            DropdownMenuItem(
                                value: 'CASH', child: Text(l.checkoutCash)),
                            if (m.upiAvailable)
                              DropdownMenuItem(
                                  value: 'UPI', child: Text(l.checkoutUpi))
                          ],
                          onChanged: (v) => setState(() => payment = v!)),
                    ],
                    DropdownButtonFormField<String>(
                        initialValue: slot,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l.subSlot),
                        items: [
                          for (final value in {
                            ...?m.plans?.timeSlots,
                            if (r != null) r.timeSlot
                          })
                            DropdownMenuItem(value: value, child: Text(value))
                        ],
                        onChanged: (v) => setState(() => slot = v),
                        validator: (v) => v == null ? l.subInvalid : null),
                    if (estimate != null) ...[
                      Text(l.subDaily(subscriptionMoney(l, estimate.daily))),
                      Text(l.subMonthly(subscriptionMoney(l, estimate.monthly),
                          subscriptionDate(s!).substring(0, 7)))
                    ],
                    if (days.isEmpty) Text(l.subInvalid),
                    Text(l.subPostpaid),
                    Text(l.subCutoff),
                    SbButton(
                        label: r == null ? l.customerSubConfirm : l.subSave,
                        onPressed: validModel && m.canWrite && days.isNotEmpty
                            ? () async {
                                if (!form.currentState!.validate()) return;
                                final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                            title: Text(l.customerSubConfirm),
                                            content: Text(l.subPostpaid),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child:
                                                      Text(l.productsCancel)),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child:
                                                      Text(l.customersConfirm))
                                            ]));
                                if (ok != true ||
                                    !mounted ||
                                    !identical(
                                        m,
                                        ref.read(
                                            customerSubscriptionsProvider)) ||
                                    !m.canWrite) {
                                  return;
                                }
                                await m.submit(
                                    r == null ? 'CREATE' : 'EDIT',
                                    {
                                      'qty': int.parse(qty.text),
                                      'weekdays': days.toList()..sort(),
                                      'timeSlot': slot,
                                      if (r != null) 'version': r.version,
                                      if (r == null) ...{
                                        'vendorId': m.vendorId,
                                        'addressId': m.addressId,
                                        'productId': product,
                                        'startDate': start.text,
                                        if (end.text.isNotEmpty)
                                          'endDate': end.text,
                                        'paymentMethod': payment
                                      }
                                    },
                                    id: r?.id);
                                if (context.mounted && m.result != null) {
                                  final id = m.result!.id;
                                  final router = GoRouter.of(context);
                                  Navigator.pop(context);
                                  if (r == null) {
                                    router.push(
                                        '/customer/orders/subscriptions/$id');
                                  }
                                }
                              }
                            : null),
                  ])),
        ])));
  }
}
