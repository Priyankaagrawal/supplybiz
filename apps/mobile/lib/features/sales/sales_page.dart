// S-V-11 / T-080: pending offline records are distinct from server receipts.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:uuid/uuid.dart';
import '../../core/l10n/l10n.dart';
import '../products/products_page.dart' show productTypeLabel;
import '../subscriptions/vendor_subscriptions_pages.dart'
    show subscriptionMoney;
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionDate;
import 'sales_controller.dart';

class _SaleLine {
  _SaleLine(this.product)
      : rate = saleDecimal(BigInt.from(product.sellingPricePaise));
  final ProductResponse product;
  String quantity = '1', rate;
  int revision = 0;
  int? get qty {
    if (quantity.length > 10 || !RegExp(r'^[1-9]\d*$').hasMatch(quantity)) {
      return null;
    }
    final n = int.tryParse(quantity);
    return n != null && n <= 2147483647 ? n : null;
  }

  BigInt? get amount =>
      qty != null && qty! <= 2147483647 && saleRupees(rate) != null
          ? saleRupees(rate)! * BigInt.from(qty!)
          : null;
}

class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});
  @override
  ConsumerState<SalesPage> createState() => _SalesState();
}

class _SalesState extends ConsumerState<SalesPage> with WidgetsBindingObserver {
  SalesController? initialized;
  String draftKey = const Uuid().v4(),
      query = '',
      customerQuery = '',
      type = 'ALL',
      method = 'CASH',
      paid = '0.00';
  String? customerId;
  bool customerMode = false, paidFull = true;
  final lines = <String, _SaleLine>{};
  int shown = 20;
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
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) ref.read(salesProvider).flush();
  }

  BigInt? get total {
    var n = BigInt.zero;
    for (final line in lines.values) {
      if (line.amount == null) return null;
      n += line.amount!;
      if (n > saleMax) return null;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(salesProvider), l = context.l10n;
    if (initialized != m) {
      initialized = m;
      lines.clear();
      draftKey = const Uuid().v4();
      customerId = null;
      Future.microtask(m.load);
    }
    final amount = total,
        paidAmount = paidFull ? amount : saleRupees(paid),
        frozen = m.saved(draftKey),
        receipt = m.receipt(draftKey);
    final valid = lines.isNotEmpty &&
        amount != null &&
        paidAmount != null &&
        paidAmount <= amount &&
        (!customerMode ? paidAmount == amount : customerId != null) &&
        lines.values
            .every((v) => v.qty != null && v.qty! <= m.available(v.product.id));
    final catalog = m.products
        .where((p) =>
            p.isActive &&
            (type == 'ALL' || p.productType == type) &&
            p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final error = switch (m.failure?.code) {
      'WALKIN_MUST_BE_PAID' => l.salesWalkinPaid,
      'INSUFFICIENT_STOCK' => l.productsInsufficient,
      'PLAN_FEATURE_LOCKED' => l.salesLocked,
      'CUSTOMER_NOT_FOUND' => l.salesCustomerMissing,
      _ => m.failure?.toMessage(l)
    };
    return Scaffold(
        appBar: AppBar(title: Text(l.salesTitle)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          if (m.busy) const SbSkeleton(lines: 2),
          if (error != null) Semantics(liveRegion: true, child: Text(error)),
          if (m.stale) Text(l.salesCached),
          SbButton(label: l.authRetry, onPressed: m.busy ? null : m.load),
          if (receipt != null) ...[
            Text(l.salesConfirmed(receipt.saleNo)),
            SbButton(label: l.salesReceipt, onPressed: () => _receipt(receipt))
          ] else if (frozen)
            Text(l.salesPending),
          if (frozen)
            SbButton(
                label: l.salesNew,
                onPressed: m.busy
                    ? null
                    : () => setState(() {
                          draftKey = const Uuid().v4();
                          lines.clear();
                          customerId = null;
                          paidFull = true;
                          paid = '0.00';
                        })),
          if (!frozen) ...[
            SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l.salesWalkin)),
                  ButtonSegment(value: true, label: Text(l.salesCustomer))
                ],
                selected: {
                  customerMode
                },
                onSelectionChanged: m.busy
                    ? null
                    : (v) => setState(() {
                          customerMode = v.single;
                          customerId = null;
                        })),
            if (customerMode) ...[
              TextField(
                  decoration: InputDecoration(labelText: l.customersSearch),
                  onChanged: (v) => setState(() => customerQuery = v)),
              DropdownButtonFormField<String>(
                  key: ValueKey('$draftKey:$customerId:$customerQuery'),
                  initialValue: customerId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.subCustomer),
                  items: [
                    for (final c in m.customers.where((c) =>
                        c.status.value == 'ACTIVE' &&
                        (c.id == customerId ||
                            '${c.name} ${c.mobile}'
                                .toLowerCase()
                                .contains(customerQuery.toLowerCase()))))
                      DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} · ${c.mobile}',
                              maxLines: 1, overflow: TextOverflow.ellipsis))
                  ],
                  onChanged:
                      m.busy ? null : (v) => setState(() => customerId = v)),
            ],
            TextField(
                decoration: InputDecoration(labelText: l.salesSearch),
                onChanged: (v) => setState(() {
                      query = v;
                      shown = 20;
                    })),
            Wrap(spacing: 8, children: [
              for (final t in {'ALL', ...m.products.map((p) => p.productType)})
                ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: ChoiceChip(
                        label: Text(productTypeLabel(l, t)),
                        selected: type == t,
                        onSelected: (_) => setState(() {
                              type = t;
                              shown = 20;
                            })))
            ]),
            if (catalog.isEmpty) SbEmpty(message: l.discoveryNoProducts),
            for (final p in catalog.take(shown))
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(p.name),
                            Text('${p.unitValue} ${p.unitType.value}'),
                            Text(subscriptionMoney(
                                l, BigInt.from(p.sellingPricePaise))),
                            Text(l.salesAvailable(m.available(p.id))),
                            SbButton(
                                label: l.salesAdd,
                                onPressed: m.canCreate &&
                                        !lines.containsKey(p.id) &&
                                        lines.length < 100 &&
                                        m.available(p.id) > 0
                                    ? () => setState(
                                        () => lines[p.id] = _SaleLine(p))
                                    : null)
                          ]))),
            if (catalog.length > shown)
              SbButton(
                  label: l.customerSubMore,
                  onPressed: () => setState(() => shown += 20)),
            for (final line in lines.values) ...[
              Text(line.product.name,
                  style: Theme.of(context).textTheme.titleMedium),
              TextFormField(
                  key:
                      ValueKey('$draftKey:${line.product.id}:${line.revision}'),
                  initialValue: line.quantity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.salesQty),
                  onChanged: (v) => setState(() => line.quantity = v)),
              Wrap(children: [
                SbIconButton(
                    icon: Icons.remove,
                    semanticLabel: l.checkoutLess,
                    onPressed: m.busy || line.qty == null || line.qty! <= 1
                        ? null
                        : () => setState(() {
                              line.quantity = '${line.qty! - 1}';
                              line.revision++;
                            })),
                SbIconButton(
                    icon: Icons.add,
                    semanticLabel: l.checkoutMore,
                    onPressed: m.busy ||
                            line.qty == null ||
                            line.qty! >= m.available(line.product.id) ||
                            line.qty! >= 2147483647
                        ? null
                        : () => setState(() {
                              line.quantity = '${line.qty! + 1}';
                              line.revision++;
                            })),
                SbIconButton(
                    icon: Icons.delete_outline,
                    semanticLabel: l.salesRemove(line.product.name),
                    onPressed: m.busy
                        ? null
                        : () => setState(() => lines.remove(line.product.id)))
              ]),
              TextFormField(
                  key: ValueKey('$draftKey:${line.product.id}:rate'),
                  initialValue: line.rate,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.salesRate),
                  onChanged: (v) => setState(() => line.rate = v)),
              Text(line.amount == null
                  ? l.salesInvalid
                  : subscriptionMoney(l, line.amount!)),
            ],
            Text(l.salesItemCount(
                lines.values.fold<int>(0, (n, v) => n + (v.qty ?? 0)))),
            Text(
                '${l.salesTotal}: ${amount == null ? l.salesInvalid : subscriptionMoney(l, amount)}'),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.salesFullPaid),
                value: paidFull,
                onChanged: m.busy ? null : (v) => setState(() => paidFull = v)),
            DropdownButtonFormField<String>(
                initialValue: method,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.subPayment),
                items: [
                  DropdownMenuItem(value: 'CASH', child: Text(l.checkoutCash)),
                  DropdownMenuItem(value: 'UPI', child: Text(l.checkoutUpi)),
                  DropdownMenuItem(value: 'OTHER', child: Text(l.productsOther))
                ],
                onChanged: m.busy ? null : (v) => setState(() => method = v!)),
            if (!paidFull)
              TextFormField(
                  key: ValueKey('$draftKey:paid'),
                  initialValue: paid,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.salesPaid),
                  onChanged: (v) => setState(() => paid = v)),
            Text(
                '${l.salesPaid}: ${paidAmount == null ? l.salesInvalid : subscriptionMoney(l, paidAmount)}'),
            Text(
                '${l.salesBalance}: ${amount == null || paidAmount == null || paidAmount > amount ? l.salesInvalid : subscriptionMoney(l, amount - paidAmount)}'),
            if (!customerMode) Text(l.salesWalkinPaid),
            if (!valid && lines.isNotEmpty) Text(l.salesInvalid),
            Text(l.salesExternal),
            SbButton(
                label: l.salesComplete,
                onPressed: m.canCreate && valid
                    ? () => _complete(m, paidAmount)
                    : null),
          ],
          Text(l.salesQueue, style: Theme.of(context).textTheme.titleLarge),
          Text(l.salesQueueInfo),
          SbButton(
              label: l.salesRetry,
              onPressed: m.busy || m.queue.isEmpty
                  ? null
                  : () => m.flush(retry: true)),
          if (m.queue.isEmpty) Text(l.salesQueueEmpty),
          for (final a in m.queue)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(a.rejected
                              ? l.salesRejected
                              : a.retryable
                                  ? l.salesNeedsRetry
                                  : l.salesPending),
                          Text(
                              '${l.salesPaid}: ${subscriptionMoney(l, BigInt.parse(a.body['paidPaise'] as String))}'),
                          if (a.code == 'INSUFFICIENT_STOCK')
                            Text(l.productsInsufficient),
                          if (a.code == 'PLAN_FEATURE_LOCKED')
                            Text(l.salesLocked),
                          if (m.canDiscard(a))
                            SbButton(
                                label: l.salesDiscard,
                                onPressed: m.busy ? null : () => _discard(m, a))
                        ]))),
          Text(l.salesReceipts, style: Theme.of(context).textTheme.titleLarge),
          for (final r in m.receipts.values.toList().reversed)
            ListTile(
                minVerticalPadding: 16,
                title: Text(r.saleNo),
                subtitle:
                    Text(subscriptionMoney(l, BigInt.parse(r.totalPaise))),
                onTap: () => _receipt(r)),
        ])));
  }

  Future<void> _complete(SalesController m, BigInt paidAmount) async {
    final l = context.l10n,
        body = [
          for (final line in lines.values)
            {
              'productId': line.product.id,
              'qty': line.qty!,
              'ratePaise': saleRupees(line.rate).toString()
            }
        ],
        key = draftKey,
        person = customerMode ? customerId : null,
        paymentMethod = method;
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(l.salesComplete),
                content: Text(
                    '${l.salesExternal}\n${l.salesTotal}: ${subscriptionMoney(l, total!)}\n${l.salesPaid}: ${subscriptionMoney(l, paidAmount)}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: Text(l.productsCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(l.customersConfirm))
                ]));
    if (ok == true &&
        mounted &&
        identical(m, ref.read(salesProvider)) &&
        m.canCreate) {
      await m.enqueue(key, body,
          customerId: person,
          paidPaise: paidAmount.toString(),
          method: paymentMethod);
    }
  }

  Future<void> _discard(SalesController m, SaleAction a) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(l.salesDiscard),
                content: Text(l.salesDiscardInfo),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: Text(l.productsCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(l.customersConfirm))
                ]));
    if (ok == true && mounted && identical(m, ref.read(salesProvider))) {
      await m.discard(a.key);
    }
  }

  Future<void> _receipt(SaleResponse r) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) {
        final l = c.l10n;
        return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.saleNo, style: Theme.of(c).textTheme.titleLarge),
                  Text(subscriptionDate(r.businessDate)),
                  for (final i in r.items) ...[
                    Text('${i.name} · ${i.unitValue} ${i.unitType}'),
                    Text(
                        '${i.qty} × ${subscriptionMoney(l, BigInt.parse(i.ratePaise))}'),
                    Text(subscriptionMoney(l, BigInt.parse(i.amountPaise)))
                  ],
                  Text(
                      '${l.salesTotal}: ${subscriptionMoney(l, BigInt.parse(r.totalPaise))}'),
                  Text(
                      '${l.salesPaid}: ${subscriptionMoney(l, BigInt.parse(r.paidPaise))}'),
                  Text(
                      '${l.salesBalance}: ${subscriptionMoney(l, BigInt.parse(r.balancePaise))}'),
                  Text(l.salesExternal)
                ]));
      });
}
