// T-081 / S-V-23–26: corrections append; customer claims are never auto-verified.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../sales/sales_controller.dart' show saleRupees, saleDecimal;
import '../subscriptions/vendor_subscriptions_pages.dart'
    show subscriptionMoney;
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionDate, subscriptionParseDate;
import 'vendor_khata_controller.dart';

class VendorKhataPage extends ConsumerStatefulWidget {
  const VendorKhataPage({this.id, this.paymentsOnly = false, super.key});
  final String? id;
  final bool paymentsOnly;
  @override
  ConsumerState<VendorKhataPage> createState() => _VendorKhataState();
}

class _VendorKhataState extends ConsumerState<VendorKhataPage>
    with WidgetsBindingObserver {
  VendorKhataController? initialized;
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
  void didUpdateWidget(VendorKhataPage old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      Future.microtask(() => ref.read(vendorKhataProvider).load(id: widget.id));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      ref.read(vendorKhataProvider).load(id: widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(vendorKhataProvider),
        l = context.l10n,
        row = widget.id == null ? null : m.find(widget.id!);
    if (initialized != m) {
      initialized = m;
      month.clear();
      Future.microtask(() => m.load(id: widget.id));
    }
    if (month.text.isEmpty && m.month != null) month.text = m.month!;
    final error = switch (m.failure?.code) {
      'PLAN_FEATURE_LOCKED' => l.khataLocked,
      'ENTRY_ALREADY_REVERSED' => l.khataAlreadyReversed,
      'CLAIM_ALREADY_DECIDED' ||
      'VERSION_CONFLICT' ||
      'CLAIM_LINK_CHANGED' =>
        l.khataChanged,
      'AMOUNT_EXCEEDS_DUE' => l.khataClaimExceeds,
      _ => m.failure?.toMessage(l)
    };
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.paymentsOnly ? l.khataPayments : l.khataTitle)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: () => m.load(id: widget.id),
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (m.busy) const SbSkeleton(lines: 2),
                      if (error != null)
                        Semantics(liveRegion: true, child: Text(error)),
                      if (m.stale) Text(l.subOffline),
                      if (m.completed)
                        Semantics(
                            liveRegion: true, child: Text(l.availabilitySaved)),
                      if (m.pending != null) ...[
                        Text(l.khataPending),
                        SbButton(
                            label: l.subRetry,
                            onPressed: m.busy ? null : m.retry)
                      ],
                      SbButton(
                          label: l.authRetry,
                          onPressed:
                              m.busy ? null : () => m.load(id: widget.id)),
                      if (m.summary != null) ...[
                        Text(
                            '${l.khataReceivable}: ${subscriptionMoney(l, BigInt.parse(m.summary!.totalReceivablePaise))}'),
                        Text(
                            '${l.khataMonthReceived}: ${subscriptionMoney(l, BigInt.parse(m.summary!.thisMonthReceivedPaise))}'),
                        if (!m.summary!.canAdjust) Text(l.khataLocked),
                        SbButton(
                            label: l.khataRecord,
                            onPressed:
                                m.canPay && (row == null || !row.archived)
                                    ? () => _form(m, 'PAYMENT', account: row)
                                    : null),
                        if (!widget.paymentsOnly)
                          SbButton(
                              label: l.khataOpening,
                              onPressed:
                                  m.canAdjust && (row == null || !row.archived)
                                      ? () => _form(m, 'OPENING', account: row)
                                      : null),
                      ],
                      if (widget.id == null && !widget.paymentsOnly) ...[
                        TextField(
                            decoration:
                                InputDecoration(labelText: l.customersSearch),
                            onChanged: (v) => m.filter(v, m.tab)),
                        DropdownButtonFormField<String>(
                            initialValue: m.tab,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.customersFilter),
                            items: [
                              DropdownMenuItem(
                                  value: 'ALL', child: Text(l.customersAll)),
                              DropdownMenuItem(
                                  value: 'RECEIVABLE',
                                  child: Text(l.khataReceivable)),
                              DropdownMenuItem(
                                  value: 'PAID', child: Text(l.khataSettled))
                            ],
                            onChanged: (v) => m.filter(m.query, v!)),
                        SbButton(
                            label: l.customersAdd,
                            onPressed: () async {
                              await const VendorCustomerNewRoute()
                                  .push<void>(context);
                              await m.load();
                            }),
                        if (m.accounts.isEmpty && !m.busy)
                          SbEmpty(message: l.khataEmpty),
                        for (final a in m.visible)
                          Card(
                              child: ListTile(
                                  minVerticalPadding: 16,
                                  title: Text(a.name),
                                  subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(a.mobile),
                                        Text(
                                            '${l.khataDebit}: ${subscriptionMoney(l, BigInt.parse(a.totalDebitPaise))}'),
                                        Text(
                                            '${l.khataCredit}: ${subscriptionMoney(l, BigInt.parse(a.totalCreditPaise))}'),
                                        Text(
                                            '${l.khataPaid}: ${subscriptionMoney(l, BigInt.parse(a.totalPaidPaise))}'),
                                        Text(
                                            '${l.khataDue}: ${subscriptionMoney(l, BigInt.parse(a.duePaise))}'),
                                        if (a.archived) Text(l.khataArchived)
                                      ]),
                                  onTap: () =>
                                      context.push('/vendor/khata/${a.id}'))),
                        if (m.visible.length < m.filtered.length)
                          SbButton(
                              label: l.customerSubMore,
                              onPressed: m.moreAccounts),
                        SbButton(
                            label: l.khataPayments,
                            onPressed: () => context.push('/vendor/payments')),
                      ],
                      if (widget.id != null) ...[
                        if (row != null) ...[
                          Text(row.name,
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(row.mobile),
                          Text(
                              '${l.khataDue}: ${subscriptionMoney(l, BigInt.parse(row.duePaise))}'),
                          if (row.archived) Text(l.khataArchived)
                        ],
                        ..._month(context, m),
                        if (m.entries != null) ...[
                          Text(
                              '${l.customerSubOpening}: ${subscriptionMoney(l, BigInt.parse(m.entries!.openingDuePaise))}'),
                          Text(
                              '${l.customerSubClosing}: ${subscriptionMoney(l, BigInt.parse(m.entries!.closingDuePaise))}'),
                          Text(l.khataNoAllocation),
                          for (final e in m.entries!.items)
                            Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(subscriptionDate(e.entryDate)),
                                          Text(e.type.value == 'DEBIT'
                                              ? l.khataDebit
                                              : l.khataCredit),
                                          Text(subscriptionMoney(
                                              l, BigInt.parse(e.amountPaise))),
                                          if (e.refType == 'OPENING')
                                            Text(l.khataOpening),
                                          if (e.refType == 'REVERSAL')
                                            Text(l.khataReversal),
                                          if (e.productSummary != null)
                                            Text(e.productSummary!),
                                          if (e.note.isNotEmpty) Text(e.note),
                                          if (e.reversesEntryId != null)
                                            Text(l.khataOriginalRetained),
                                          SbButton(
                                              label: l.khataReverse,
                                              onPressed: m.canAdjust &&
                                                      row?.archived == false &&
                                                      !m.entries!.items.any((r) =>
                                                          r.reversesEntryId ==
                                                          e.id)
                                                  ? () => _form(m, 'REVERSE',
                                                      entry: e, account: row)
                                                  : null)
                                        ]))),
                          if (m.entries!.items.length < m.entries!.total)
                            SbButton(
                                label: l.customerSubMore,
                                onPressed: m.busy ? null : m.moreEntries),
                        ] else if (!m.busy)
                          Text(l.networkNotFound),
                      ],
                      if (widget.paymentsOnly) ...[
                        ..._month(context, m),
                        Text(l.khataCollections,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(l.khataNetInfo),
                        if (m.collections.isEmpty && !m.busy)
                          Text(l.khataCollectionsEmpty),
                        for (final c in m.collections)
                          Card(
                              child: ListTile(
                                  minVerticalPadding: 16,
                                  title: Text(c.customerName),
                                  subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(c.entryDate),
                                        Text(l.khataRecordedAt(
                                            DateFormat('yMMMd HH:mm', 'en')
                                                .format(
                                                    DateTime.parse(c.createdAt)
                                                        .toUtc()
                                                        .add(const Duration(
                                                            hours: 5,
                                                            minutes: 30))))),
                                        Text(_method(l, c.method)),
                                        Text(subscriptionMoney(
                                            l, BigInt.parse(c.amountPaise))),
                                        if (c.reversal) Text(l.khataReversal)
                                      ]))),
                        if (m.collections.length < m.collectionTotal)
                          SbButton(
                              label: l.customerSubMore,
                              onPressed: m.busy ? null : m.moreCollections),
                      ],
                      if (widget.id != null || widget.paymentsOnly) ...[
                        Text(l.khataClaims,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(l.khataClaimInfo),
                        DropdownButtonFormField<String>(
                            key: ValueKey(m.claimStatus),
                            initialValue: m.claimStatus,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.khataClaims),
                            items: [
                              DropdownMenuItem(
                                  value: 'PENDING',
                                  child: Text(l.khataClaimPending)),
                              DropdownMenuItem(
                                  value: 'CONFIRMED',
                                  child: Text(l.khataClaimConfirmed)),
                              DropdownMenuItem(
                                  value: 'REJECTED',
                                  child: Text(l.khataClaimRejected))
                            ],
                            onChanged:
                                m.busy ? null : (v) => m.selectClaims(v!)),
                        for (final c in m.claims.where((c) =>
                            widget.id == null ||
                            c.vendorCustomerId == widget.id))
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(m.find(c.vendorCustomerId)?.name ??
                                            l.subCustomer),
                                        Text(subscriptionMoney(
                                            l, BigInt.parse(c.amountPaise))),
                                        Text(_method(l, c.method.value)),
                                        if (c.upiTxnRef != null)
                                          Text(c.upiTxnRef!),
                                        if (c.rejectReason != null)
                                          Text(c.rejectReason!),
                                        if (c.status.value == 'PENDING') ...[
                                          SbButton(
                                              label: l.khataConfirmClaim,
                                              onPressed: m.canPay
                                                  ? () => _confirmClaim(m, c)
                                                  : null),
                                          SbButton(
                                              label: l.khataRejectClaim,
                                              onPressed: m.canPay
                                                  ? () => _form(m, 'REJECT',
                                                      claim: c)
                                                  : null),
                                        ]
                                      ]))),
                        if (m.claims.length < m.claimTotal)
                          SbButton(
                              label: l.customerSubMore,
                              onPressed: m.busy ? null : m.moreClaims),
                      ],
                    ]))));
  }

  List<Widget> _month(BuildContext context, VendorKhataController m) => [
        TextField(
            controller: month,
            decoration:
                InputDecoration(labelText: context.l10n.customerSubMonth),
            onChanged: (_) => setState(() {})),
        SbButton(
            label: context.l10n.khataShowMonth,
            onPressed: !m.busy &&
                    RegExp(r'^[0-9]{4}-(0[1-9]|1[0-2])$')
                        .hasMatch(month.text) &&
                    !month.text.startsWith('0000')
                ? () => m.selectMonth(month.text)
                : null),
      ];
  Future<void> _form(VendorKhataController m, String action,
      {VendorKhataAccount? account,
      KhataLedgerEntry? entry,
      PaymentClaimRecord? claim}) async {
    final accounts = List<VendorKhataAccount>.of(m.accounts),
        businessDate = m.summary!.businessDate;
    final input = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _KhataForm(
            action: action,
            accounts: accounts,
            account: account,
            entry: entry,
            businessDate: businessDate,
            canSubmit: () =>
                mounted &&
                identical(m, ref.read(vendorKhataProvider)) &&
                m.canWrite));
    if (input == null ||
        !mounted ||
        !identical(m, ref.read(vendorKhataProvider)) ||
        !m.canWrite) {
      return;
    }
    if (action == 'REJECT') input['version'] = claim!.version;
    await m.submit(action, input,
        id: action == 'REVERSE'
            ? entry!.id
            : action == 'OPENING'
                ? input.remove('vendorCustomerId') as String
                : claim?.id);
  }

  Future<void> _confirmClaim(
      VendorKhataController m, PaymentClaimRecord c) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(l.khataConfirmClaim),
                content: Text(
                    '${l.khataClaimInfo}\n${subscriptionMoney(l, BigInt.parse(c.amountPaise))}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.productsCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.customersConfirm))
                ]));
    if (ok == true &&
        mounted &&
        identical(m, ref.read(vendorKhataProvider)) &&
        m.canPay) {
      await m.submit('CONFIRM', {'version': c.version}, id: c.id);
    }
  }
}

String _method(AppLocalizations l, String value) => switch (value) {
      'CASH' => l.checkoutCash,
      'UPI' => l.checkoutUpi,
      'BANK' => l.khataBank,
      'WALLET' => l.khataWallet,
      _ => l.productsOther
    };

class _KhataForm extends StatefulWidget {
  const _KhataForm(
      {required this.action,
      required this.accounts,
      required this.businessDate,
      required this.canSubmit,
      this.account,
      this.entry});
  final String action, businessDate;
  final List<VendorKhataAccount> accounts;
  final VendorKhataAccount? account;
  final KhataLedgerEntry? entry;
  final bool Function() canSubmit;
  @override
  State<_KhataForm> createState() => _KhataFormState();
}

class _KhataFormState extends State<_KhataForm> {
  final form = GlobalKey<FormState>(),
      amount = TextEditingController(),
      note = TextEditingController();
  late final TextEditingController date;
  String? account;
  String method = 'CASH', type = 'DEBIT';
  @override
  void initState() {
    super.initState();
    account = widget.account?.id;
    date = TextEditingController(text: widget.businessDate);
    final due = BigInt.tryParse(widget.account?.duePaise ?? '0') ?? BigInt.zero;
    if (widget.action == 'PAYMENT' && due > BigInt.zero) {
      amount.text = saleDecimal(due);
    }
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n,
        a = widget.action,
        title = switch (a) {
          'PAYMENT' => l.khataRecord,
          'OPENING' => l.khataOpening,
          'REVERSE' => l.khataReverse,
          _ => l.khataRejectClaim
        };
    return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
            child: Form(
                key: form,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (a == 'PAYMENT' || a == 'OPENING') ...[
                        if (widget.account == null)
                          DropdownButtonFormField<String>(
                              initialValue: account,
                              isExpanded: true,
                              decoration:
                                  InputDecoration(labelText: l.subCustomer),
                              items: [
                                for (final c in widget.accounts
                                    .where((c) => !c.archived))
                                  DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis))
                              ],
                              onChanged: (v) => setState(() => account = v),
                              validator: (v) => v == null ? l.subInvalid : null)
                        else
                          Text(widget.account!.name),
                        TextFormField(
                            controller: amount,
                            maxLength: 20,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                InputDecoration(labelText: l.khataAmount),
                            validator: (v) => saleRupees(v ?? '') == null ||
                                    saleRupees(v ?? '')! <= BigInt.zero
                                ? l.khataInvalidAmount
                                : null),
                      ],
                      if (a == 'OPENING')
                        DropdownButtonFormField<String>(
                            initialValue: type,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.khataEntryType),
                            items: [
                              DropdownMenuItem(
                                  value: 'DEBIT', child: Text(l.khataDebit)),
                              DropdownMenuItem(
                                  value: 'CREDIT', child: Text(l.khataCredit))
                            ],
                            onChanged: (v) => setState(() => type = v!)),
                      if (a == 'PAYMENT') ...[
                        Text(l.salesExternal),
                        DropdownButtonFormField<String>(
                            initialValue: method,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.subPayment),
                            items: [
                              for (final code in [
                                'CASH',
                                'UPI',
                                'BANK',
                                'WALLET'
                              ])
                                DropdownMenuItem(
                                    value: code, child: Text(_method(l, code)))
                            ],
                            onChanged: (v) => setState(() => method = v!)),
                        TextFormField(
                            controller: date,
                            readOnly: true,
                            decoration:
                                InputDecoration(labelText: l.khataReceivedOn),
                            onTap: () async {
                              final day = subscriptionParseDate(date.text)!;
                              final chosen = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      DateTime(day.year, day.month, day.day),
                                  firstDate: DateTime(1),
                                  lastDate: DateTime(9999, 12, 31));
                              if (chosen != null && mounted) {
                                date.text = subscriptionDate(chosen);
                              }
                            },
                            validator: (v) =>
                                subscriptionParseDate(v ?? '') == null
                                    ? l.subInvalid
                                    : null),
                      ],
                      if (widget.entry != null) ...[
                        Text(subscriptionMoney(
                            l, BigInt.parse(widget.entry!.amountPaise))),
                        Text(l.khataOriginalRetained)
                      ],
                      TextFormField(
                          controller: note,
                          maxLength:
                              a == 'PAYMENT' || a == 'REJECT' ? 200 : 500,
                          decoration: InputDecoration(
                              labelText:
                                  a == 'PAYMENT' ? l.khataNote : l.subReason),
                          validator: (v) => a == 'PAYMENT'
                              ? null
                              : v == null || v.trim().isEmpty
                                  ? l.subInvalid
                                  : null),
                    ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.productsCancel)),
          TextButton(
              onPressed: () {
                if (!widget.canSubmit() || !form.currentState!.validate()) {
                  return;
                }
                final body = <String, dynamic>{
                  if (a == 'PAYMENT' || a == 'OPENING')
                    'vendorCustomerId': account,
                  if (a == 'PAYMENT' || a == 'OPENING')
                    'amountPaise': saleRupees(amount.text).toString(),
                  if (a == 'PAYMENT') ...{
                    'method': method,
                    'receivedOn': date.text,
                    'note': note.text.trim()
                  },
                  if (a == 'OPENING') ...{
                    'type': type,
                    'note': note.text.trim()
                  },
                  if (a == 'REVERSE' || a == 'REJECT')
                    'reason': note.text.trim()
                };
                Navigator.pop(context, body);
              },
              child: Text(l.customersConfirm))
        ]);
  }
}
