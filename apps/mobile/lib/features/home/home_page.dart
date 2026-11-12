// S-C-01 / T-043
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../notifications/notifications_controller.dart';
import 'home_controller.dart';

String homeStatus(AppLocalizations l, String status) => switch (status) {
      'NEW' => l.homeStatusNew,
      'ACCEPTED' => l.homeStatusAccepted,
      'PREPARING' => l.homeStatusPreparing,
      'OUT_FOR_DELIVERY' => l.homeStatusOut,
      'DELIVERED' => l.homeStatusDelivered,
      'REJECTED' => l.homeStatusRejected,
      'CANCELLED' => l.homeStatusCancelled,
      'FAILED' => l.homeStatusFailed,
      _ => l.homeStatusUnknown,
    };

class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});
  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) unawaited(ref.read(notificationsProvider).load('CUSTOMER'));
    });
  }

  Future<void> refresh() async {
    await Future.wait([
      ref.read(homeProvider).load(),
      ref.read(notificationsProvider).load('CUSTOMER')
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(homeProvider),
        inbox = ref.watch(notificationsProvider),
        l = context.l10n;
    final data = model.home, location = model.location;
    final unread =
        inbox.role == 'CUSTOMER' && inbox.failure == null ? inbox.unread : 0;
    return Scaffold(
        appBar: AppBar(title: Text(l.appName), actions: [
          Stack(children: [
            SbIconButton(
                icon: Icons.notifications_outlined,
                semanticLabel:
                    unread > 0 ? l.homeUnread(unread) : l.routeNotifications,
                onPressed: () async {
                  await const CommonRoute(CommonPage.notifications)
                      .push<void>(context);
                  if (mounted) {
                    unawaited(ref.read(notificationsProvider).load('CUSTOMER'));
                  }
                }),
            if (unread > 0)
              Positioned(
                  right: 8,
                  top: 8,
                  child: ExcludeSemantics(
                      child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle))))
          ]),
          SbIconButton(
              icon: Icons.manage_accounts_outlined,
              semanticLabel: l.routeSettings,
              onPressed: () =>
                  const CommonRoute(CommonPage.settings).push<void>(context)),
        ]),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      SbButton(
                          label: location == null
                              ? l.homeChooseLocation
                              : l.homeLocation(location.address, location.city,
                                  location.pincode),
                          variant: SbButtonVariant.secondary,
                          onPressed: model.busy
                              ? null
                              : () => const CustomerLocationRoute()
                                  .push<void>(context)),
                      const SizedBox(height: 12),
                      SbButton(
                          label: l.homeSearchTitle,
                          variant: SbButtonVariant.secondary,
                          onPressed: () =>
                              const CustomerSearchRoute().push<void>(context)),
                      SbButton(
                          label: l.discoveryVendors,
                          onPressed: () => const CustomerDiscoveryRoute()
                              .push<void>(context)),
                      if (model.busy) const SbSkeleton(lines: 2),
                      if (model.failure != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(model.failure!.toMessage(l))),
                      if (model.stale) Text(l.homeStale),
                      SbButton(
                          label: l.homeRefresh,
                          variant: SbButtonVariant.secondary,
                          onPressed: model.busy ? null : refresh),
                      if (data != null) ...[
                        Semantics(
                            header: true,
                            child: Text(l.homeCategories,
                                style: Theme.of(context).textTheme.titleLarge)),
                        if (data.categories.isEmpty)
                          SbEmpty(message: l.homeNoCategories),
                        LayoutBuilder(builder: (context, constraints) {
                          final largeText =
                              MediaQuery.textScalerOf(context).scale(16) >= 24;
                          final columns = largeText
                              ? 1
                              : constraints.maxWidth >= 600
                                  ? 3
                                  : 2;
                          final width =
                              (constraints.maxWidth - 8 * (columns - 1)) /
                                  columns;
                          return Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final category in data.categories)
                              SizedBox(
                                  width: width,
                                  child: SbButton(
                                      label: category.available
                                          ? category.name
                                          : l.homeComingSoon(category.name),
                                      variant: SbButtonVariant.secondary,
                                      onPressed:
                                          category.available && !model.stale
                                              ? () => CustomerSearchRoute(
                                                      category: category.id)
                                                  .push<void>(context)
                                              : null)),
                          ]);
                        }),
                        const SizedBox(height: 20),
                        Semantics(
                            header: true,
                            child: Text(l.homeToday,
                                style: Theme.of(context).textTheme.titleLarge)),
                        Text(DateFormat.yMMMd('en').format(data.businessDate)),
                        if (data.deliveries.isEmpty)
                          SbEmpty(message: l.homeNoDeliveries),
                        for (final row in data.deliveries)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(row.vendorName ?? l.homeVendor),
                                        Text(l.homeOrder(row.orderNo)),
                                        Text(row.timeSlot),
                                        Semantics(
                                            liveRegion: true,
                                            child: Text(homeStatus(
                                                l, row.status.value))),
                                        for (final item in row.items)
                                          Text(l.homeProduct(
                                              item.name, item.qty)),
                                      ]))),
                        if (data.nextCursor != null)
                          SbButton(
                              label: l.homeMoreDeliveries,
                              onPressed: model.busy || model.stale
                                  ? null
                                  : model.more),
                      ],
                    ]))));
  }
}
