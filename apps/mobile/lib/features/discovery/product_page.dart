// S-C-08 / T-044: MOQ/stock controls and revalidated single-vendor cart intent.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import 'cart_controller.dart';
import 'discovery_controller.dart';
import 'discovery_widgets.dart';

class CustomerProductPage extends ConsumerStatefulWidget {
  const CustomerProductPage(
      {required this.id, required this.productId, super.key});
  final String id, productId;
  @override
  ConsumerState<CustomerProductPage> createState() =>
      _CustomerProductPageState();
}

class _CustomerProductPageState extends ConsumerState<CustomerProductPage> {
  VendorController? initialized;
  int? qty;
  bool checking = false;
  String? message;
  Future<void> add(VendorController model, ProductResponse displayed) async {
    setState(() {
      checking = true;
      message = null;
    });
    try {
      var product = await model.fresh(widget.productId);
      if (!mounted || product == null) return;
      bool changed(ProductResponse p) =>
          p.version != displayed.version ||
          p.sellingPricePaise != displayed.sellingPricePaise ||
          p.moq != displayed.moq ||
          p.stockQty != displayed.stockQty;
      if (changed(product)) {
        setState(() {
          qty = product!.moq;
          message = context.l10n.discoveryChanged;
        });
        return;
      }
      final cart = ref.read(cartProvider), name = model.about?.businessName;
      if (name == null) return;
      var result = await cart.add(widget.id, name, product, qty!);
      if (!mounted) return;
      if (result == CartChange.replaceVendor) {
        if (!await discoveryConfirm(
                context, context.l10n.discoveryReplaceCart) ||
            !mounted) {
          return;
        }
        product = await model.fresh(widget.productId);
        if (!mounted || product == null) return;
        if (changed(product)) {
          setState(() {
            qty = product!.moq;
            message = context.l10n.discoveryChanged;
          });
          return;
        }
        result = await cart.add(widget.id, name, product, qty!, replace: true);
      }
      if (mounted) {
        setState(() => message = result == CartChange.saved
            ? context.l10n.discoveryAdded
            : context.l10n.discoveryCartError);
      }
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(vendorProvider(widget.id)),
        cart = ref.watch(cartProvider),
        l = context.l10n;
    if (initialized != model) {
      initialized = model;
      qty = null;
      Future.microtask(model.load);
    }
    final p = model.product(widget.productId);
    if (p != null) qty ??= p.moq;
    return Scaffold(
        appBar: AppBar(
            title: Text(p?.name ?? l.discoveryOpenProduct),
            actions: const [CartButton()]),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          if (model.busy) const SbSkeleton(),
          if (model.failure != null)
            Semantics(
                liveRegion: true, child: Text(model.failure!.toMessage(l))),
          if (model.location == null)
            SbButton(
                label: l.homeChooseLocation,
                onPressed: () =>
                    const CustomerLocationRoute().push<void>(context)),
          SbButton(
              label: l.authRetry,
              variant: SbButtonVariant.secondary,
              onPressed: model.busy || checking ? null : model.load),
          if (p != null && model.about != null) ...[
            VendorImage(
                key: ValueKey('${identityHashCode(model)}:${p.imageMediaId}'),
                model: model,
                mediaId: p.imageMediaId),
            Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(formatInr(p.sellingPricePaise)),
            Text(l.discoveryPack('${p.unitValue}', p.unitType.value)),
            if (p.milkType != null)
              Text(l.discoveryMilkType(switch (p.milkType) {
                'COW' => l.productsCow,
                'BUFFALO' => l.productsBuffalo,
                'TONED' => l.productsToned,
                'DOUBLE_TONED' => l.productsDoubleToned,
                'FULL_CREAM' => l.productsFullCream,
                _ => l.productsOther
              })),
            Text(p.description),
            Text(l.discoveryMoq(p.moq)),
            if (p.stockQty < p.moq) Text(l.discoveryOutOfStock),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  SbIconButton(
                      icon: Icons.remove,
                      semanticLabel: l.discoveryDecrease,
                      onPressed: !checking && qty! > p.moq
                          ? () => setState(() => qty = qty! - 1)
                          : null),
                  Semantics(
                      liveRegion: true, child: Text(l.discoveryQuantity(qty!))),
                  SbIconButton(
                      icon: Icons.add,
                      semanticLabel: l.discoveryIncrease,
                      onPressed: !checking && qty! < p.stockQty
                          ? () => setState(() => qty = qty! + 1)
                          : null),
                ]),
            if (message != null)
              Semantics(liveRegion: true, child: Text(message!)),
            if (cart.failure != null) Text(cart.failure!.toMessage(l)),
            SbButton(
                label: l.discoveryAddCart,
                loading: checking,
                onPressed: cart.canEdit &&
                        !model.busy &&
                        p.stockQty >= qty! &&
                        qty! >= p.moq
                    ? () => add(model, p)
                    : null),
          ] else if (!model.busy &&
              model.failure == null &&
              model.location != null)
            Text(l.networkNotFound),
        ])));
  }
}
