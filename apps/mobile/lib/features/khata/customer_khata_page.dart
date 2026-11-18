// T-083 / S-C-17–20. Vendor ledger is read-only; personal entries are owned CRUD.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr/qr.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../sales/sales_controller.dart' show saleRupees, saleDecimal;
import '../subscriptions/vendor_subscriptions_pages.dart'
    show subscriptionMoney;
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionDate, subscriptionParseDate;
import 'customer_khata_controller.dart';

class CustomerKhataPage extends ConsumerStatefulWidget {
  const CustomerKhataPage({this.scope = 'home', super.key});
  final String scope;
  @override
  ConsumerState<CustomerKhataPage> createState() => _CustomerKhataState();
}

class _CustomerKhataState extends ConsumerState<CustomerKhataPage>
    with WidgetsBindingObserver {
  CustomerKhataController? initialized;
  final month = TextEditingController();
  String? monthError;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(customerKhataProvider(widget.scope)).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(customerKhataProvider(widget.scope)), l = context.l10n;
    if (initialized != m) {
      initialized = m;
      month.clear();
      Future.microtask(m.load);
    }
    if (month.text.isEmpty && m.month != null) month.text = m.month!;
    String money(String v) => subscriptionMoney(l, BigInt.parse(v));
    final error = switch (m.failure?.code) {
      'PAYMENT_DETAILS_CHANGED' ||
      'UPI_NOT_AVAILABLE' =>
        l.customerKhataChanged,
      'AMOUNT_EXCEEDS_DUE' => l.khataClaimExceeds,
      _ => m.failure?.toMessage(l)
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.khataTitle)),
      body: SafeArea(
          child: RefreshIndicator(
              onRefresh: m.load,
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
                          liveRegion: true, child: Text(l.customerKhataSaved)),
                    if (m.deleted) Text(l.khataEmpty),
                    if (m.pending != null) ...[
                      Text(l.khataPending),
                      SbButton(
                          label: l.subRetry, onPressed: m.busy ? null : m.retry)
                    ],
                    SbButton(
                        label: l.authRetry, onPressed: m.busy ? null : m.load),
                    if (m.summary != null && widget.scope == 'home') ...[
                      Text(
                          '${l.khataReceivable}: ${money(m.summary!.totalReceivablePaise)}'),
                      Text(
                          '${l.customerKhataPayable}: ${money(m.summary!.totalPayablePaise)}'),
                      Text(
                          '${l.customerKhataNet}: ${money(m.summary!.netBalancePaise)}'),
                      TextField(
                          decoration:
                              InputDecoration(labelText: l.customersSearch),
                          onChanged: (q) => m.filter(q, m.tab)),
                      DropdownButtonFormField<String>(
                          initialValue: m.tab,
                          isExpanded: true,
                          decoration:
                              InputDecoration(labelText: l.customersFilter),
                          items: ['ALL', 'CUSTOMERS', 'VENDORS']
                              .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v == 'ALL'
                                      ? l.customersAll
                                      : v == 'CUSTOMERS'
                                          ? l.customerKhataPersonal
                                          : l.customerKhataVendors)))
                              .toList(),
                          onChanged: (v) => m.filter(m.query, v!)),
                      SbButton(
                          label: l.customerKhataAdd,
                          onPressed: m.canWrite
                              ? () => _edit(m, 'CONTACT_CREATE')
                              : null),
                      if (m.filtered.isEmpty) SbEmpty(message: l.khataEmpty),
                      for (final a in m.visible)
                        Card(
                            child: ListTile(
                                minVerticalPadding: 16,
                                title: Text(a.name),
                                subtitle: Text(
                                    '${money(a.balancePaise)} · ${_balance(l, a.balancePaise)}'),
                                onTap: () async {
                                  await context.push(a.kind.value == 'VENDOR'
                                      ? '/customer/khata/${a.id}'
                                      : '/customer/personal-khata/${a.id}');
                                  await m.load();
                                })),
                      if (m.visible.length < m.filtered.length)
                        SbButton(
                            label: l.customerSubMore,
                            onPressed: m.moreAccounts),
                    ],
                    if ((m.vendorId != null || m.contactId != null) &&
                        m.summary != null &&
                        !m.deleted) ...[
                      if (m.entries != null)
                        Text(m.entries!.vendorName,
                            style: Theme.of(context).textTheme.titleLarge),
                      if (m.contact != null) ...[
                        Text(m.contact!.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        if (m.contact!.mobile != null) Text(m.contact!.mobile!),
                        Text(
                            '${l.customerKhataBalance}: ${money(m.contact!.balancePaise)} · ${_balance(l, m.contact!.balancePaise)}'),
                        SbButton(
                            label: l.customerKhataEdit,
                            onPressed: m.canWrite
                                ? () => _edit(m, 'CONTACT_PATCH')
                                : null),
                        SbButton(
                            label: l.customerKhataDelete,
                            onPressed: m.canWrite ? () => _delete(m) : null),
                        SbButton(
                            label: l.customerKhataAddEntry,
                            onPressed: m.canWrite
                                ? () => _edit(m, 'ENTRY_CREATE')
                                : null),
                      ],
                      TextField(
                          controller: month,
                          decoration: InputDecoration(
                              labelText: l.customerSubMonth,
                              errorText: monthError)),
                      SbButton(
                          label: l.customerKhataApplyMonth,
                          onPressed: m.busy
                              ? null
                              : () async {
                                  final valid =
                                      RegExp(r'^\d{4}-(0[1-9]|1[0-2])$')
                                              .hasMatch(month.text) &&
                                          subscriptionParseDate(
                                                  '${month.text}-01') !=
                                              null;
                                  setState(() => monthError = valid
                                      ? null
                                      : l.customerKhataInvalidMonth);
                                  if (valid) await m.selectMonth(month.text);
                                }),
                      if (m.entries != null) ...[
                        Text('${l.khataDue}: ${money(m.entries!.duePaise)}'),
                        Text(
                            '${l.customerSubOpening}: ${money(m.entries!.openingDuePaise)}'),
                        Text(
                            '${l.customerSubClosing}: ${money(m.entries!.closingDuePaise)}'),
                        Text(
                            '${l.customerKhataMonthTotal}: ${money(m.entries!.monthDebitPaise)}'),
                        Text(
                            '${l.customerKhataMonthPaid}: ${money(m.entries!.monthPaidPaise)}'),
                        Text(l.khataNoAllocation),
                        if (m.entries!.items.isEmpty)
                          SbEmpty(message: l.khataEmpty),
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
                                        Text(money(e.amountPaise)),
                                        if (e.productSummary != null)
                                          Text(e.productSummary!),
                                        Text(
                                            '${l.customerKhataSource}: ${_source(l, e.refType)}'),
                                        if (e.paymentStatus != null)
                                          Text(e.paymentStatus == 'PAID'
                                              ? l.ordersPaid
                                              : l.ordersUnpaid)
                                        else
                                          Text(l.customerKhataUnallocated),
                                        if (e.note.isNotEmpty) Text(e.note),
                                        if (e.reversesEntryId != null)
                                          Text(l.khataOriginalRetained),
                                      ]))),
                        if (m.entries!.items.length < m.entries!.total)
                          SbButton(
                              label: l.customerSubMore,
                              onPressed: m.busy ? null : m.moreEntries),
                        SbButton(
                            label: l.customerKhataSettle,
                            onPressed: m.canWrite ? () => _settle(m) : null),
                        Text(l.khataClaims,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(l.khataClaimInfo),
                        DropdownButtonFormField<String>(
                            initialValue: m.claimStatus,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.khataClaims),
                            items: ['PENDING', 'CONFIRMED', 'REJECTED']
                                .map((v) => DropdownMenuItem(
                                    value: v, child: Text(_status(l, v))))
                                .toList(),
                            onChanged:
                                m.busy ? null : (v) => m.selectClaims(v!)),
                        if (m.claims.isEmpty) Text(l.khataEmpty),
                        for (final c in m.claims)
                          Card(
                              child: ListTile(
                                  minVerticalPadding: 16,
                                  title: Text(money(c.amountPaise)),
                                  subtitle: Text([
                                    _status(l, c.status.value),
                                    c.method.value == 'UPI'
                                        ? l.customerKhataMethodUpi
                                        : l.customerKhataMethodCash,
                                    if (c.rejectReason != null) c.rejectReason!,
                                  ].join('\n')))),
                        if (m.claims.length < m.claimTotal)
                          SbButton(
                              label: l.customerSubMore,
                              onPressed: m.busy ? null : m.moreClaims),
                      ],
                      if (m.contact != null) ...[
                        if (m.personal.isEmpty) SbEmpty(message: l.khataEmpty),
                        for (final e in m.personal)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(subscriptionDate(e.date)),
                                        Text(e.direction.value == 'GAVE'
                                            ? l.customerKhataGave
                                            : l.customerKhataGot),
                                        Text(money(e.amountPaise)),
                                        if (e.note.isNotEmpty) Text(e.note),
                                        SbButton(
                                            label: l.customerKhataEditEntry,
                                            onPressed: m.canWrite
                                                ? () => _edit(m, 'ENTRY_PATCH',
                                                    entry: e)
                                                : null),
                                        SbButton(
                                            label: l.customerKhataDeleteEntry,
                                            onPressed: m.canWrite
                                                ? () => _delete(m, entry: e)
                                                : null),
                                      ]))),
                        if (m.personal.length < m.personalTotal)
                          SbButton(
                              label: l.customerSubMore,
                              onPressed: m.busy ? null : m.morePersonal),
                      ],
                    ],
                    if (m.launch != null && m.summary != null) ...[
                      Text(l.customerKhataPendingReview),
                      Text(l.customerKhataReview),
                      Text(
                          '${m.launch!['payee']}\n${money(m.launch!['amountPaise'] as String)}'),
                      SelectableText(m.launch!['vpa'] as String),
                      if (m.launch!['fallback'] == true)
                        Text(l.customerKhataFallback),
                      KhataPaymentQr(uri: m.launch!['uri'] as String),
                      SbButton(
                          label: l.customerKhataCopy,
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(
                                text: m.launch!['vpa'] as String));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(l.customerKhataCopied)));
                            }
                          }),
                      SbButton(
                          label: l.customerKhataPaid,
                          onPressed: m.canReview ? m.confirmPaid : null),
                      SbButton(
                          label: l.customerKhataNotPaid,
                          onPressed: m.busy || m.pending != null
                              ? null
                              : m.dismissPayment),
                    ],
                  ]))),
    );
  }

  Future<void> _edit(CustomerKhataController m, String action,
      {PersonalEntryRecord? entry}) async {
    final body = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _PersonalEditor(
            action: action,
            contact: m.contact,
            entry: entry,
            businessDate: subscriptionDate(m.summary!.businessDate)));
    if (body != null) {
      await m.submit(action, body, id: entry?.id ?? m.contactId);
    }
  }

  Future<void> _delete(CustomerKhataController m,
      {PersonalEntryRecord? entry}) async {
    final l = context.l10n;
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(entry == null
                    ? l.customerKhataDelete
                    : l.customerKhataDeleteEntry),
                content: Text(entry == null
                    ? l.customerKhataDeleteConfirm
                    : l.customerKhataDeleteEntryConfirm),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.subCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.customerKhataConfirm))
                ]));
    if (yes == true) {
      await m.submit(entry == null ? 'CONTACT_DELETE' : 'ENTRY_DELETE',
          {'version': entry?.version ?? m.contact!.version},
          id: entry?.id ?? m.contactId);
    }
  }

  Future<void> _settle(CustomerKhataController m) async {
    await m.settlementOptions();
    if (!mounted || m.options == null || m.stale) return;
    final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _SettlementEditor(options: m.options!));
    if (result != null) {
      await m.pay(result['account'] as String,
          BigInt.parse(result['amount'] as String), result['method'] as String);
    }
  }
}

String _balance(AppLocalizations l, String value) {
  final v = BigInt.parse(value);
  return v > BigInt.zero
      ? l.khataReceivable
      : v < BigInt.zero
          ? l.customerKhataPayable
          : l.khataSettled;
}

String _status(AppLocalizations l, String v) => switch (v) {
      'CONFIRMED' => l.khataClaimConfirmed,
      'REJECTED' => l.khataClaimRejected,
      _ => l.khataClaimPending
    };
String _source(AppLocalizations l, String v) => switch (v) {
      'OPENING' => l.khataOpening,
      'REVERSAL' => l.khataReversal,
      'CLAIM' => l.khataClaims,
      'PAYMENT' => l.khataPayments,
      'SALE' || 'QUICK_SALE' || 'POS' => l.salesTitle,
      _ => l.ordersApp
    };

class _PersonalEditor extends StatefulWidget {
  const _PersonalEditor(
      {required this.action,
      required this.businessDate,
      this.contact,
      this.entry});
  final String action, businessDate;
  final PersonalContactRecord? contact;
  final PersonalEntryRecord? entry;
  @override
  State<_PersonalEditor> createState() => _PersonalEditorState();
}

class _PersonalEditorState extends State<_PersonalEditor> {
  final name = TextEditingController(),
      mobile = TextEditingController(),
      amount = TextEditingController(),
      date = TextEditingController(),
      note = TextEditingController();
  String direction = 'GAVE';
  bool invalid = false;
  bool get isContact => widget.action.startsWith('CONTACT');
  @override
  void initState() {
    super.initState();
    name.text = widget.contact?.name ?? '';
    mobile.text = widget.contact?.mobile ?? '';
    date.text = widget.entry == null
        ? widget.businessDate
        : subscriptionDate(widget.entry!.date);
    if (widget.entry != null) {
      direction = widget.entry!.direction.value;
      amount.text = saleDecimal(BigInt.parse(widget.entry!.amountPaise));
      note.text = widget.entry!.note;
    }
  }

  @override
  void dispose() {
    for (final c in [name, mobile, amount, date, note]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
        scrollable: true,
        title: Text(isContact ? l.customerKhataEdit : l.customerKhataEditEntry),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isContact) ...[
                TextField(
                    controller: name,
                    maxLength: 120,
                    decoration:
                        InputDecoration(labelText: l.customerKhataName)),
                TextField(
                    controller: mobile,
                    maxLength: 16,
                    keyboardType: TextInputType.phone,
                    decoration:
                        InputDecoration(labelText: l.customerKhataMobile)),
              ] else ...[
                DropdownButtonFormField<String>(
                    initialValue: direction,
                    isExpanded: true,
                    decoration:
                        InputDecoration(labelText: l.customerKhataDirection),
                    items: [
                      DropdownMenuItem(
                          value: 'GAVE', child: Text(l.customerKhataGave)),
                      DropdownMenuItem(
                          value: 'GOT', child: Text(l.customerKhataGot))
                    ],
                    onChanged: (v) => setState(() => direction = v!)),
                TextField(
                    controller: amount,
                    maxLength: 20,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.khataAmount)),
                TextField(
                    controller: date,
                    decoration: InputDecoration(labelText: l.ordersDate)),
                TextField(
                    controller: note,
                    maxLength: 500,
                    decoration: InputDecoration(labelText: l.khataNote)),
              ],
              if (invalid)
                Semantics(liveRegion: true, child: Text(l.customerKhataInvalid))
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.subCancel)),
          TextButton(
              onPressed: () {
                final value = saleRupees(amount.text);
                final valid = isContact
                    ? name.text.trim().isNotEmpty &&
                        (mobile.text.trim().isEmpty ||
                            RegExp(r'^\+?\d{7,15}$')
                                .hasMatch(mobile.text.trim()))
                    : value != null &&
                        value > BigInt.zero &&
                        subscriptionParseDate(date.text) != null;
                if (!valid) {
                  setState(() => invalid = true);
                  return;
                }
                Navigator.pop(context, <String, dynamic>{
                  if (widget.action.endsWith('PATCH'))
                    'version': isContact
                        ? widget.contact!.version
                        : widget.entry!.version,
                  if (isContact) ...{
                    'name': name.text.trim(),
                    if (mobile.text.trim().isNotEmpty)
                      'mobile': mobile.text.trim(),
                    if (mobile.text.trim().isEmpty &&
                        widget.action == 'CONTACT_PATCH')
                      'clearMobile': true
                  } else ...{
                    'contactId': widget.contact!.id,
                    'direction': direction,
                    'amountPaise': value.toString(),
                    'date': date.text,
                    'note': note.text.trim()
                  }
                });
              },
              child: Text(l.customerKhataConfirm))
        ]);
  }
}

class _SettlementEditor extends StatefulWidget {
  const _SettlementEditor({required this.options});
  final CustomerSettlementOptions options;
  @override
  State<_SettlementEditor> createState() => _SettlementEditorState();
}

class _SettlementEditorState extends State<_SettlementEditor> {
  final amount = TextEditingController();
  String? account;
  bool invalid = false;
  List<KhataBillingAccount> get eligible => widget.options.accounts
      .where((a) => a.canClaim && BigInt.parse(a.maxClaimPaise) > BigInt.zero)
      .toList();
  @override
  void initState() {
    super.initState();
    account = eligible.firstOrNull?.vendorCustomerId;
    _prefillAmount();
  }

  void _prefillAmount() {
    final a = eligible.where((a) => a.vendorCustomerId == account).firstOrNull;
    if (a == null) return;
    var value = BigInt.parse(widget.options.duePaise);
    for (final cap in [a.duePaise, a.maxClaimPaise]) {
      final n = BigInt.parse(cap);
      if (n < value) value = n;
    }
    amount.text = saleDecimal(value);
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  void finish(String method) {
    final v = saleRupees(amount.text),
        a = eligible.where((a) => a.vendorCustomerId == account).firstOrNull;
    if (v == null ||
        v <= BigInt.zero ||
        a == null ||
        v > BigInt.parse(a.maxClaimPaise) ||
        v > BigInt.parse(a.duePaise) ||
        v > BigInt.parse(widget.options.duePaise)) {
      setState(() => invalid = true);
      return;
    }
    Navigator.pop(context,
        {'account': account, 'amount': v.toString(), 'method': method});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, o = widget.options;
    return AlertDialog(
        scrollable: true,
        title: Text(l.customerKhataSettle),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(o.payeeName),
              Text(
                  '${l.khataDue}: ${subscriptionMoney(l, BigInt.parse(o.duePaise))}'),
              Text(l.khataClaimInfo),
              if (!o.upiAvailable) Text(l.customerKhataCashOnly),
              if (o.upiAvailable && o.upiId != null) SelectableText(o.upiId!),
              if (eligible.isEmpty)
                Text(l.customerKhataNoDue)
              else ...[
                DropdownButtonFormField<String>(
                    initialValue: account,
                    isExpanded: true,
                    decoration:
                        InputDecoration(labelText: l.customerKhataAccount),
                    items: eligible
                        .asMap()
                        .entries
                        .map((e) => DropdownMenuItem(
                            value: e.value.vendorCustomerId,
                            child: Text(
                                '${e.key + 1} · ${l.customerKhataDueLimit}: ${subscriptionMoney(l, BigInt.parse(e.value.maxClaimPaise))}')))
                        .toList(),
                    onChanged: (v) => setState(() {
                          account = v;
                          _prefillAmount();
                        })),
                TextField(
                    controller: amount,
                    maxLength: 20,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.khataAmount)),
                if (invalid)
                  Semantics(
                      liveRegion: true, child: Text(l.customerKhataInvalid)),
                if (o.upiAvailable && o.upiId != null)
                  SbButton(
                      label: l.customerKhataUpi,
                      onPressed: () => finish('UPI')),
                if (o.cashAvailable) ...[
                  Text(l.customerKhataConfirmCash),
                  SbButton(
                      label: l.customerKhataCash,
                      onPressed: () => finish('CASH'))
                ],
              ]
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(l.subCancel))
        ]);
  }
}

// Real offline QR of exactly the URI sent to Android; four-module quiet zone.
class KhataPaymentQr extends StatelessWidget {
  const KhataPaymentQr({required this.uri, super.key});
  final String uri;
  @override
  Widget build(BuildContext context) => Semantics(
      label: context.l10n.customerKhataQr,
      image: true,
      child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(painter: _QrPainter(uri))))));
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.uri)
      : matrix = QrImage(QrCode.fromData(
            data: uri, errorCorrectLevel: QrErrorCorrectLevel.M));
  final String uri;
  final QrImage matrix;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final unit = size.shortestSide / (matrix.moduleCount + 8),
        paint = Paint()
          ..color = Colors.black
          ..isAntiAlias = false;
    for (var y = 0; y < matrix.moduleCount; y++) {
      for (var x = 0; x < matrix.moduleCount; x++) {
        if (matrix.isDark(y, x)) {
          canvas.drawRect(
              Rect.fromLTWH((x + 4) * unit, (y + 4) * unit, unit, unit), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => uri != old.uri;
}
