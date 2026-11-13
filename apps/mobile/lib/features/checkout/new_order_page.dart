// S-C-12 / T-046: one-time Milk & Dairy / Water Can products from a chosen vendor.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../discovery/cart_controller.dart';
import '../discovery/discovery_controller.dart';
import '../discovery/discovery_widgets.dart';

class NewOrderPage extends ConsumerStatefulWidget {
  const NewOrderPage({required this.id, super.key});
  final String id;
  @override
  ConsumerState<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends ConsumerState<NewOrderPage> {
  VendorController? initialized;
  bool water = false;
  final quantities = <String, int>{};
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(vendorProvider(widget.id)),
        cart = ref.watch(cartProvider),
        l = context.l10n;
    if (initialized != m) {
      initialized = m;
      Future.microtask(m.load);
    }
    final products = m.products
        .where((p) => water
            ? p.productType == 'WATER_CAN'
            : ['MILK', 'CURD', 'PANEER', 'GHEE', 'BUTTER']
                .contains(p.productType))
        .toList();
    return Scaffold(
        appBar:
            AppBar(title: Text(l.checkoutNew), actions: const [CartButton()]),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.checkoutOneTime),
          Wrap(spacing: 8, children: [
            SbButton(
                label: l.checkoutMilk,
                variant:
                    water ? SbButtonVariant.secondary : SbButtonVariant.primary,
                onPressed: () => setState(() => water = false)),
            SbButton(
                label: l.checkoutWater,
                variant:
                    water ? SbButtonVariant.primary : SbButtonVariant.secondary,
                onPressed: () => setState(() => water = true)),
          ]),
          if (m.busy) const SbSkeleton(),
          if (m.failure != null) Text(m.failure!.toMessage(l)),
          if (!m.busy && products.isEmpty)
            SbEmpty(message: l.discoveryNoProducts),
          SbButton(
              label: l.authRetry,
              variant: SbButtonVariant.secondary,
              onPressed: m.busy ? null : m.load),
          for (final p in products)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(p.name),
                          Text(formatInr(p.sellingPricePaise)),
                          Text(l.checkoutQuantity(quantities[p.id] ?? p.moq)),
                          Wrap(children: [
                            SbIconButton(
                                icon: Icons.remove,
                                semanticLabel: l.checkoutLess,
                                onPressed: (quantities[p.id] ?? p.moq) > p.moq
                                    ? () => setState(() => quantities[p.id] =
                                        (quantities[p.id] ?? p.moq) - 1)
                                    : null),
                            SbIconButton(
                                icon: Icons.add,
                                semanticLabel: l.checkoutMore,
                                onPressed: (quantities[p.id] ?? p.moq) <
                                        p.stockQty
                                    ? () => setState(() => quantities[p.id] =
                                        (quantities[p.id] ?? p.moq) + 1)
                                    : null),
                          ]),
                          SbButton(
                              label: l.discoveryAddCart,
                              onPressed: cart.canEdit &&
                                      !m.busy &&
                                      p.stockQty >= p.moq
                                  ? () async {
                                      final fresh = await m.fresh(p.id);
                                      if (fresh == null || !context.mounted) {
                                        return;
                                      }
                                      var changed = await cart.add(
                                          widget.id,
                                          m.about?.businessName ?? l.homeVendor,
                                          fresh,
                                          quantities[p.id] ?? p.moq);
                                      if (changed == CartChange.replaceVendor &&
                                          context.mounted &&
                                          await discoveryConfirm(context,
                                              l.discoveryReplaceCart)) {
                                        changed = await cart.add(
                                            widget.id,
                                            m.about?.businessName ??
                                                l.homeVendor,
                                            fresh,
                                            quantities[p.id] ?? p.moq,
                                            replace: true);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    changed == CartChange.saved
                                                        ? l.discoveryAdded
                                                        : l.checkoutStock)));
                                      }
                                    }
                                  : null),
                        ]))),
          SbButton(
              label: l.checkoutTitle,
              onPressed: cart.lines.isEmpty
                  ? null
                  : () => const CustomerCartRoute().push<void>(context)),
        ])));
  }
}
