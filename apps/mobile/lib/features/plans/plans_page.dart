// T-105 / S-V-27/28. Catalog is information; support assigns/renews plans.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../subscriptions/vendor_subscriptions_pages.dart'
    show subscriptionMoney;
import 'plans_controller.dart';

const planFeatureCodes = [
  'BASIC_ORDER_MANAGEMENT',
  'QUICK_SALE',
  'KHATA',
  'PAYMENT_RECORDS',
  'BASIC_REPORTS',
  'SUBSCRIPTIONS',
  'DELIVERY_MANAGEMENT',
  'AUTO_ACCEPT',
  'STOCK_MANAGEMENT',
  'STOCK_ALERTS',
  'ADVANCED_REPORTS'
];
String planFeature(AppLocalizations l, String feature) => switch (feature) {
      'BASIC_ORDER_MANAGEMENT' => l.plansOrders,
      'QUICK_SALE' => l.salesTitle,
      'KHATA' => l.khataTitle,
      'PAYMENT_RECORDS' => l.khataPayments,
      'BASIC_REPORTS' => l.plansBasicReports,
      'SUBSCRIPTIONS' => l.dashSubscriptions,
      'DELIVERY_MANAGEMENT' => l.plansDelivery,
      'AUTO_ACCEPT' => l.plansAutoAccept,
      'STOCK_MANAGEMENT' => l.plansStock,
      'STOCK_ALERTS' => l.plansStockAlerts,
      'ADVANCED_REPORTS' => l.plansAdvancedReports,
      _ => l.plansAdditionalFeature,
    };
String planStatus(AppLocalizations l, String status) => switch (status) {
      'ACTIVE' => l.plansActive,
      'UNASSIGNED' => l.plansUnassigned,
      'SCHEDULED' => l.plansScheduled,
      'EXPIRED' => l.plansExpired,
      _ => l.plansUnavailable,
    };
String planValidity(DateTime value) => DateFormat('MMM d, y HH:mm', 'en')
    .format(value.toUtc().add(const Duration(hours: 5, minutes: 30)));

class PlansPage extends ConsumerStatefulWidget {
  const PlansPage({super.key});
  @override
  ConsumerState<PlansPage> createState() => _PlansState();
}

class _PlansState extends ConsumerState<PlansPage> with WidgetsBindingObserver {
  PlansController? initialized;
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
    if (s == AppLifecycleState.resumed) ref.read(plansProvider).load();
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(plansProvider),
        l = context.l10n,
        c = m.current,
        a = c?.assignment;
    if (initialized != m) {
      initialized = m;
      Future.microtask(m.load);
    }
    final failures = {
      if (m.currentFailure != null) m.currentFailure!.toMessage(l),
      if (m.catalogFailure != null) m.catalogFailure!.toMessage(l)
    };
    return Scaffold(
        appBar: AppBar(title: Text(l.dashPlans)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (m.busy) const SbSkeleton(lines: 2),
                      for (final message in failures)
                        Semantics(liveRegion: true, child: Text(message)),
                      if (m.cacheUnavailable) Text(l.plansCacheUnavailable),
                      SbButton(
                          label: l.authRetry,
                          onPressed: m.busy ? null : m.load),
                      Text(l.plansSupport),
                      Text(l.plansNoTrial),
                      Text(l.plansCurrent,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (m.currentStale && c != null)
                        Text(l.plansSavedCurrent),
                      if (c == null && !m.busy) Text(l.plansCurrentMissing),
                      if (c != null) ...[
                        Text(planStatus(l, c.status.value),
                            style: Theme.of(context).textTheme.titleMedium),
                        if (a != null) ...[
                          Text(a.code),
                          Text(l.plansStarts(planValidity(a.startsAt))),
                          Text(l.plansEnds(planValidity(a.endsAt))),
                        ],
                        Text(l.plansCapacity(
                            c.activeCustomers, c.customerLimit)),
                        if (c.status.value == 'UNASSIGNED')
                          Text(l.plansSetup(c.customerLimit)),
                        if (c.status.value == 'EXPIRED')
                          Text(l.plansExpiryRules),
                        if (c.status.value == 'SCHEDULED')
                          Text(l.dashPlanScheduled),
                        if (!c.canAddCustomer) ...[
                          Text(c.activeCustomers >= c.customerLimit
                              ? l.plansAtLimit
                              : l.plansGrowthBlocked),
                          Text(l.plansRetained),
                        ],
                        Text(l.plansAssignedFeatures,
                            style: Theme.of(context).textTheme.titleMedium),
                        for (final code in planFeatureCodes)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ExcludeSemantics(
                                        child: Icon(c.features.contains(code)
                                            ? Icons.check_circle_outline
                                            : Icons.lock_outline)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            '${planFeature(l, code)}: ${c.features.contains(code) ? l.plansIncluded : l.plansLocked}')),
                                  ])),
                        Text(l.plansFeatureNotice),
                      ],
                      Text(l.plansCatalog,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (m.catalogStale && m.catalogLoaded)
                        Text(l.plansSavedCatalog),
                      if (m.catalogLoaded && m.catalog.isEmpty)
                        SbEmpty(message: l.plansEmpty),
                      for (final p in m.catalog)
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
                                              .titleLarge),
                                      if (p.isPopular)
                                        Text(l.customerSubPopular),
                                      Text(
                                          l.plansCatalogLimit(p.customerLimit)),
                                      if (p.prices.isEmpty)
                                        Text(l.plansPriceUnavailable),
                                      for (final price in p.prices)
                                        Text(l.plansCatalogPrice(
                                            switch (price.duration.value) {
                                              'MONTHLY' => l.plansMonthly,
                                              'HALF_YEARLY' =>
                                                l.plansHalfYearly,
                                              _ => l.plansYearly
                                            },
                                            subscriptionMoney(
                                                l,
                                                BigInt.from(
                                                    price.pricePaise)))),
                                      for (final f in p.features)
                                        Text(planFeature(l, f)),
                                    ]))),
                    ]))));
  }
}
