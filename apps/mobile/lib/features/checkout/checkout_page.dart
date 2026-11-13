// S-C-11 / T-046. Only a reviewed server quote can be submitted.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/app_failure.dart';
import '../../core/router/routes.dart';
import '../discovery/cart_controller.dart';
import 'checkout_controller.dart';

String checkoutError(AppFailure f, AppLocalizations l) => switch (f.code) {
      'BELOW_MOQ' => l.checkoutMoq,
      'OUT_OF_STOCK' || 'PRODUCT_UNAVAILABLE' => l.checkoutStock,
      'NOT_SERVICEABLE' => l.checkoutCoverage,
      'PAST_CUTOFF' ||
      'INVALID_DELIVERY_DATE' ||
      'INVALID_TIME_SLOT' =>
        l.checkoutTiming,
      'VENDOR_HOLIDAY' ||
      'DELIVERY_PAUSED' ||
      'CAPACITY_REACHED' =>
        l.checkoutUnavailable,
      'MIN_ORDER_NOT_MET' => l.checkoutMinimum,
      'CUSTOMER_LINK_REQUIRED' => l.checkoutLink,
      'CUSTOMER_INACTIVE' => l.checkoutInactive,
      'PRICE_CHANGED' => l.checkoutPriceChanged,
      _ => f.toMessage(l),
    };

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(checkoutProvider),
        cart = ref.watch(cartProvider),
        l = context.l10n;
    final completed = m.result;
    return Scaffold(
        appBar: AppBar(title: Text(l.checkoutTitle)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          if (m.busy || cart.busy) const SbSkeleton(),
          if (m.failure != null)
            Semantics(
                liveRegion: true, child: Text(checkoutError(m.failure!, l))),
          if (cart.failure != null) Text(cart.failure!.toMessage(l)),
          if (m.pending != null) ...[
            Text(l.checkoutPending),
            SbButton(
                label: l.checkoutRetry, onPressed: m.busy ? null : m.retry),
          ],
          if (completed != null) ...[
            Semantics(
                liveRegion: true,
                child: Text(l.checkoutPlaced(completed.orderNo))),
            Text(formatInr(int.parse(completed.totalPaise))),
            if (m.pending == null)
              SbButton(
                  label: l.checkoutContinue,
                  onPressed: m.busy
                      ? null
                      : () async {
                          await m.finish();
                          if (context.mounted && m.result == null) {
                            const CustomerHomeRoute().go(context);
                          }
                        }),
          ] else ...[
            if (cart.ready && cart.lines.isEmpty)
              SbEmpty(message: l.discoveryCartEmpty),
            for (final row in cart.lines)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(row.product.name,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(row.vendorName),
                            Text(l.checkoutQuantity(row.qty)),
                            Wrap(spacing: 8, children: [
                              SbIconButton(
                                  icon: Icons.remove,
                                  semanticLabel: l.checkoutLess,
                                  onPressed: cart.canEdit &&
                                          !m.busy &&
                                          row.qty > row.product.moq
                                      ? () => cart.quantity(
                                          row.product.id, row.qty - 1)
                                      : null),
                              SbIconButton(
                                  icon: Icons.add,
                                  semanticLabel: l.checkoutMore,
                                  onPressed: cart.canEdit &&
                                          !m.busy &&
                                          row.qty < row.product.stockQty
                                      ? () => cart.quantity(
                                          row.product.id, row.qty + 1)
                                      : null),
                              SbButton(
                                  label: l.checkoutRemove,
                                  variant: SbButtonVariant.secondary,
                                  onPressed: cart.canEdit && !m.busy
                                      ? () => cart.quantity(row.product.id, 0)
                                      : null),
                            ]),
                            if (m.productErrorId == row.product.id &&
                                m.failure != null)
                              Text(checkoutError(m.failure!, l)),
                          ]))),
            if (cart.lines.isNotEmpty) ...[
              SbButton(
                  label: l.checkoutRefresh,
                  onPressed: m.busy || m.pending != null ? null : m.load),
              if (m.addresses.isEmpty && m.ready) Text(l.checkoutNoAddress),
              SbButton(
                  label: l.addressAdd,
                  variant: SbButtonVariant.secondary,
                  onPressed: m.canChoose
                      ? () async {
                          await const CustomerAddressNewRoute()
                              .push<void>(context);
                          await m.load();
                        }
                      : null),
              if (m.addresses.isNotEmpty)
                DropdownButtonFormField<String>(
                    key: ValueKey(
                        'address:${m.addressId}:${m.addresses.length}'),
                    initialValue: m.addressId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.checkoutAddress),
                    items: m.addresses
                        .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.label}: ${a.line1}, ${a.city}',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: m.canChoose
                        ? (id) {
                            if (id != null) m.chooseAddress(id);
                          }
                        : null),
              if (m.options case final options?) ...[
                if (options.availableDates.isEmpty || options.timeSlots.isEmpty)
                  Text(l.checkoutNoSlots),
                if (options.availableDates.isNotEmpty)
                  DropdownButtonFormField<String>(
                      key: ValueKey('date:${m.date}:${options.serverTime}'),
                      initialValue: m.date,
                      decoration: InputDecoration(labelText: l.checkoutDate),
                      items: options.availableDates
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: m.canChoose
                          ? (v) {
                              if (v != null) m.choose(deliveryDate: v);
                            }
                          : null),
                if (options.timeSlots.isNotEmpty)
                  DropdownButtonFormField<String>(
                      key: ValueKey('slot:${m.slot}:${options.serverTime}'),
                      initialValue: m.slot,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.checkoutSlot),
                      items: options.timeSlots
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: m.canChoose
                          ? (v) {
                              if (v != null) m.choose(timeSlot: v);
                            }
                          : null),
                if (options.sameDayCutoff != null)
                  Text(l.checkoutCutoff(options.sameDayCutoff!)),
              ],
              DropdownButtonFormField<String>(
                  initialValue: m.payment,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.checkoutPayment),
                  items: [
                    DropdownMenuItem(
                        value: 'POD_CASH',
                        child: Text(l.checkoutCash,
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'POD_UPI',
                        child: Text(l.checkoutUpi,
                            overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: m.canChoose
                      ? (v) {
                          if (v != null) m.choose(mode: v);
                        }
                      : null),
              SbButton(
                  label: l.checkoutQuote,
                  onPressed: m.canQuote ? m.refreshQuote : null),
              if (m.quote case final quote?) ...[
                if (m.priceChanged) Text(l.checkoutPriceChanged),
                for (final line in quote.items)
                  Text(
                      '${line.name} × ${line.qty}: ${formatInr(int.parse(line.lineTotalPaise))}'),
                Text(l.checkoutSubtotal(
                    formatInr(int.parse(quote.subtotalPaise)))),
                Text(l.checkoutDelivery(quote.deliveryChargePaise == '0'
                    ? l.checkoutFree
                    : formatInr(int.parse(quote.deliveryChargePaise)))),
                Text(l.checkoutTotal(formatInr(int.parse(quote.totalPaise))),
                    style: Theme.of(context).textTheme.titleLarge),
                SbButton(
                    label: m.priceChanged
                        ? l.checkoutConfirmPrice
                        : l.checkoutPlace,
                    onPressed: m.canPlace ? m.place : null),
              ],
            ],
          ],
        ])));
  }
}
