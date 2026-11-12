// S-C-05 / S-C-37 / T-044
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import 'discovery_controller.dart';
import 'favorites_controller.dart';
import 'discovery_widgets.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({this.category, this.favorites = false, super.key});
  final String? category;
  final bool favorites;
  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  DiscoveryController? initialized;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(discoveryProvider(
            (category: widget.category, favorites: widget.favorites))),
        fav = ref.watch(favoritesProvider),
        l = context.l10n;
    if (initialized != m) {
      initialized = m;
      Future.microtask(m.load);
    }
    ref.listen(
        favoritesProvider.select((m) => m.revision), (_, __) => m.load());
    return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.favorites ? l.discoveryFavorites : l.discoveryVendors),
            actions: [
              const CartButton(),
              if (!widget.favorites)
                SbIconButton(
                    icon: Icons.favorite_outline,
                    semanticLabel: l.discoveryFavorites,
                    onPressed: () =>
                        const CustomerFavoritesRoute().push<void>(context))
            ]),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      const FavoriteFeedback(),
                      if (m.location == null)
                        SbButton(
                            label: l.homeChooseLocation,
                            onPressed: () => const CustomerLocationRoute()
                                .push<void>(context))
                      else ...[
                        DropdownButtonFormField<String>(
                            key: ValueKey(m),
                            initialValue: m.sort,
                            decoration:
                                InputDecoration(labelText: l.discoverySort),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                  value: 'NEARBY',
                                  child: Text(l.discoveryNearby)),
                              DropdownMenuItem(
                                  value: 'POPULAR',
                                  child: Text(l.discoveryPopular))
                            ],
                            onChanged: m.busy
                                ? null
                                : (value) {
                                    if (value != null) m.load(order: value);
                                  }),
                        if (m.busy) const SbSkeleton(),
                        if (m.failure != null)
                          Semantics(
                              liveRegion: true,
                              child: Text(m.failure!.toMessage(l))),
                        SbButton(
                            label: l.authRetry,
                            variant: SbButtonVariant.secondary,
                            onPressed: m.busy ? null : m.load),
                        if (m.ready && m.items.isEmpty)
                          SbEmpty(
                              message: widget.favorites
                                  ? l.discoveryNoFavorites
                                  : l.homeSearchEmpty),
                        for (final row in m.items)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Semantics(
                                            header: true,
                                            child: Text(row.businessName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge)),
                                        Text(l.homeDistance(
                                            (row.distanceMeters / 1000)
                                                .toStringAsFixed(1))),
                                        for (final badge in row.badges)
                                          Text(badge),
                                        SbButton(
                                            label: row.favorite
                                                ? l.discoveryUnfavorite
                                                : l.discoveryFavorite,
                                            variant: SbButtonVariant.secondary,
                                            onPressed: fav.canEdit && !m.busy
                                                ? () => fav.set(
                                                    row.id, !row.favorite)
                                                : null),
                                        SbButton(
                                            label: l.discoveryOpenVendor,
                                            onPressed: () =>
                                                CustomerVendorRoute(row.id)
                                                    .push<void>(context)),
                                      ]))),
                        if (m.cursor != null)
                          SbButton(
                              label: l.homeMoreVendors,
                              onPressed:
                                  m.busy ? null : () => m.load(more: true)),
                      ]
                    ]))));
  }
}
