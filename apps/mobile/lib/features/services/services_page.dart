// S-C-04 / FR-270 / T-122: supply directory; no deferred payment actions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../home/home_controller.dart';

class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reuse the scoped home source, including current-session checks, refresh,
    // cancellation on account/role changes and the selected discovery location.
    final model = ref.watch(homeProvider), l = context.l10n;
    final categories = model.home?.categories;
    return Scaffold(
        appBar: AppBar(title: Text(l.navServices)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: model.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(l.servicesDescription),
                      if (model.busy) const SbSkeleton(lines: 2),
                      if (model.failure != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(model.failure!.toMessage(l))),
                      if (model.stale && categories != null)
                        Text(l.servicesStale),
                      SbButton(
                          label: l.servicesRefresh,
                          variant: SbButtonVariant.secondary,
                          onPressed: model.busy ? null : model.load),
                      if (!model.busy &&
                          categories != null &&
                          categories.isEmpty)
                        SbEmpty(message: l.homeNoCategories),
                      for (final category in categories ?? <HomeCategory>[])
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SbButton(
                                label: category.available &&
                                        category.status ==
                                            HomeCategoryStatusEnum.ENABLED
                                    ? category.name
                                    : l.homeComingSoon(category.name),
                                variant: SbButtonVariant.secondary,
                                onPressed: category.available &&
                                        category.status ==
                                            HomeCategoryStatusEnum.ENABLED &&
                                        !model.stale &&
                                        !model.busy
                                    ? () => CustomerDiscoveryRoute(
                                            category: category.id)
                                        .push<void>(context)
                                    : null)),
                    ]))));
  }
}
