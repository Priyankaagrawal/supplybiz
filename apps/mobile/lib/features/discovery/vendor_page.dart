// S-C-06/07 / T-044: real read tabs; subscription creation belongs to T-078.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import 'discovery_controller.dart';
import 'favorites_controller.dart';
import 'discovery_widgets.dart';

class CustomerVendorPage extends ConsumerStatefulWidget {
  const CustomerVendorPage({required this.id, super.key});
  final String id;
  @override
  ConsumerState<CustomerVendorPage> createState() => _CustomerVendorPageState();
}

class _CustomerVendorPageState extends ConsumerState<CustomerVendorPage> {
  VendorController? initialized;
  String tab = 'products';
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(vendorProvider(widget.id)),
        fav = ref.watch(favoritesProvider),
        l = context.l10n;
    if (initialized != m) {
      initialized = m;
      Future.microtask(m.load);
    }
    ref.listen(
        favoritesProvider.select((m) => m.revision), (_, __) => m.load());
    final vendor = m.about;
    return Scaffold(
        appBar: AppBar(
            title: Text(vendor?.businessName ?? l.homeVendor),
            actions: const [CartButton()]),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      const FavoriteFeedback(),
                      if (m.busy) const SbSkeleton(),
                      if (m.failure != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(m.failure!.toMessage(l))),
                      if (m.location == null)
                        SbButton(
                            label: l.homeChooseLocation,
                            onPressed: () => const CustomerLocationRoute()
                                .push<void>(context)),
                      SbButton(
                          label: l.authRetry,
                          variant: SbButtonVariant.secondary,
                          onPressed: m.busy ? null : m.load),
                      if (vendor != null) ...[
                        VendorImage(
                            key: ValueKey(
                                '${identityHashCode(m)}:${vendor.shopPhotoMediaId}'),
                            model: m,
                            mediaId: vendor.shopPhotoMediaId),
                        Text(l.homeDistance(
                            (vendor.distanceMeters / 1000).toStringAsFixed(1))),
                        for (final badge in vendor.badges) Text(badge),
                        SbButton(
                            label: l.checkoutNew,
                            onPressed: () => CustomerNewOrderRoute(widget.id)
                                .push<void>(context)),
                        SbButton(
                            label: vendor.favorite
                                ? l.discoveryUnfavorite
                                : l.discoveryFavorite,
                            variant: SbButtonVariant.secondary,
                            onPressed: fav.canEdit
                                ? () => fav.set(vendor.id, !vendor.favorite)
                                : null),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final entry in {
                            'products': l.navProducts,
                            'subscription': l.discoverySubscription,
                            'about': l.discoveryAbout
                          }.entries)
                            Semantics(
                                selected: tab == entry.key,
                                child: SbButton(
                                    label: entry.value,
                                    variant: tab == entry.key
                                        ? SbButtonVariant.primary
                                        : SbButtonVariant.secondary,
                                    onPressed: () =>
                                        setState(() => tab = entry.key)))
                        ]),
                        if (tab == 'about') ...[
                          Text([
                            vendor.address,
                            vendor.city,
                            vendor.state,
                            vendor.pincode
                          ]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(', ')),
                          Text(l.discoveryDeliveryCharge(
                              formatInr(vendor.deliveryChargePaise))),
                          Text(l.discoveryMinimumOrder(
                              formatInr(vendor.minOrderPaise))),
                          Text(l.discoveryHoursUnavailable),
                          Text(l.discoveryHolidays,
                              style: Theme.of(context).textTheme.titleMedium),
                          if (vendor.holidays.isEmpty)
                            Text(l.discoveryNoHolidays),
                          for (final h in vendor.holidays)
                            Text(
                                '${h.date?.toIso8601String().substring(0, 10) ?? ''}: ${h.reason ?? ''}'),
                        ] else ...[
                          if (tab == 'subscription')
                            Text(l.discoverySubscriptionInfo),
                          if (m.products
                              .where((p) =>
                                  tab != 'subscription' ||
                                  p.subscriptionPricePaise != null)
                              .isEmpty)
                            SbEmpty(message: l.discoveryNoProducts),
                          for (final p in m.products.where((p) =>
                              tab != 'subscription' ||
                              p.subscriptionPricePaise != null))
                            Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(p.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          Text(formatInr(tab == 'subscription'
                                              ? p.subscriptionPricePaise!
                                              : p.sellingPricePaise)),
                                          Text(l.discoveryPack('${p.unitValue}',
                                              p.unitType.value)),
                                          SbButton(
                                              label: l.discoveryOpenProduct,
                                              onPressed: () =>
                                                  CustomerProductRoute(
                                                          widget.id, p.id)
                                                      .push<void>(context)),
                                        ]))),
                        ]
                      ]
                    ]))));
  }
}
