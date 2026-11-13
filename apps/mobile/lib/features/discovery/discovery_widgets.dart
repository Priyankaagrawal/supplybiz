import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import 'cart_controller.dart';
import 'favorites_controller.dart';
import 'discovery_controller.dart';
import '../../core/router/routes.dart';

Future<bool> discoveryConfirm(BuildContext context, String message) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                content: SingleChildScrollView(child: Text(message)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.l10n.productsCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.l10n.customersConfirm))
                ])) ??
    false;

class CartButton extends ConsumerWidget {
  const CartButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider), l = context.l10n;
    return Badge.count(
        count: cart.count,
        isLabelVisible: cart.count > 0,
        child: SbIconButton(
            icon: Icons.shopping_cart_outlined,
            semanticLabel: l.discoveryCart(cart.count),
            onPressed: () => const CustomerCartRoute().push<void>(context)));
  }
}

class FavoriteFeedback extends ConsumerWidget {
  const FavoriteFeedback({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(favoritesProvider), l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (m.failure != null)
        Semantics(liveRegion: true, child: Text(m.failure!.toMessage(l))),
      if (m.failure != null && !m.ready)
        SbButton(label: l.authRetry, onPressed: m.busy ? null : m.load),
      if (m.pending != null) ...[
        Text(m.expired ? l.discoveryRetryExpired : l.discoveryRetryPending),
        SbButton(
            label: m.expired ? l.discoveryDismiss : l.customersRetrySaved,
            onPressed: m.busy
                ? null
                : () async {
                    if (!m.expired) {
                      await m.retry();
                    } else if (await discoveryConfirm(
                            context, l.discoveryDismissConfirm) &&
                        context.mounted) {
                      await m.dismissExpired();
                    }
                  })
      ],
    ]);
  }
}

class VendorImage extends StatelessWidget {
  const VendorImage({required this.model, required this.mediaId, super.key});
  final VendorController model;
  final String? mediaId;
  @override
  Widget build(BuildContext context) {
    if (mediaId == null) return const SizedBox.shrink();
    return FutureBuilder(
        future: model.image(mediaId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
                height: 80, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == null) {
            return Text(context.l10n.discoveryImageUnavailable);
          }
          return Image.memory(snapshot.data!,
              height: 160,
              fit: BoxFit.contain,
              semanticLabel: context.l10n.discoveryImage,
              errorBuilder: (_, __, ___) =>
                  Text(context.l10n.discoveryImageUnavailable));
        });
  }
}
