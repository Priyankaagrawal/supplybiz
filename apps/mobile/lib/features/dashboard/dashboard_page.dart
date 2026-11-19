// T-031 / S-V-05/S-V-19. Existing five-branch shell retains each navigation stack.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../../core/router/guards.dart';
import '../subscriptions/vendor_subscriptions_pages.dart'
    show subscriptionMoney, subscriptionAmount;
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionParseDate;
import 'dashboard_controller.dart';

String dashboardLitres(String value) {
  final parts = value.split('.'),
      fraction =
          parts.length < 2 ? '' : parts[1].replaceFirst(RegExp(r'0+$'), '');
  final whole = subscriptionAmount(BigInt.parse(parts[0]) * BigInt.from(100))
      .split('.')
      .first;
  return '$whole${fraction.isEmpty ? '' : '.$fraction'}';
}

String dashboardUpdated(DateTime value) => DateFormat('MMM d, y HH:mm', 'en')
    .format(value.toUtc().add(const Duration(hours: 5, minutes: 30)));

class VendorDashboardPage extends ConsumerStatefulWidget {
  const VendorDashboardPage({super.key});
  @override
  ConsumerState<VendorDashboardPage> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<VendorDashboardPage>
    with WidgetsBindingObserver {
  DashboardController? initialized;
  final date = TextEditingController();
  String? error, syncedDate;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    date.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(dashboardProvider).load();
  }

  Future<void> open(DashboardController m, String route) async {
    await context.push(route);
    await m.load();
  }

  void orders(DashboardController m, String filter) {
    final day = m.selectedDate;
    if (day == null) return;
    open(
        m,
        Uri(
            path: '/vendor/dashboard-orders',
            queryParameters: {'date': day, 'filter': filter}).toString());
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(dashboardProvider), l = context.l10n, v = m.metrics;
    if (initialized != m) {
      initialized = m;
      date.clear();
      Future.microtask(m.load);
    }
    if (syncedDate != m.selectedDate) {
      syncedDate = m.selectedDate;
      date.text = m.selectedDate ?? '';
    }
    String money(String value) => subscriptionMoney(l, BigInt.parse(value));
    return Scaffold(
        appBar: AppBar(title: Text(l.navHome), actions: [
          SbIconButton(
              icon: Icons.notifications_outlined,
              semanticLabel: l.routeNotifications,
              onPressed: () => const CommonRoute(CommonPage.notifications)
                  .push<void>(context)),
          SbIconButton(
              icon: Icons.settings_outlined,
              semanticLabel: l.routeSettings,
              onPressed: () =>
                  const CommonRoute(CommonPage.settings).push<void>(context)),
        ]),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      DashboardFeedback(model: m),
                      if (v != null) ...[
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                  image: true,
                                  label: l.dashShopPhoto,
                                  child: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: ClipOval(
                                          child: m.hasPhoto
                                              ? Image.memory(m.photo!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                          Icons.storefront,
                                                          size: 48))
                                              : const Icon(Icons.storefront,
                                                  size: 48)))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(v.shopName ?? l.dashShopMissing,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    Text(v.city ?? l.dashCityMissing),
                                    if (v.verified) Text(l.onboardingVerified),
                                  ])),
                            ]),
                        DashboardBanners(model: m),
                        Text(l.dashSelectedDate(m.selectedDate ?? '')),
                        TextField(
                            controller: date,
                            enabled: !m.busy,
                            decoration: InputDecoration(
                                labelText: l.ordersDate, errorText: error)),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          SbButton(
                              label: l.dashApplyDate,
                              onPressed: m.busy
                                  ? null
                                  : () async {
                                      final valid =
                                          subscriptionParseDate(date.text) !=
                                              null;
                                      setState(() => error =
                                          valid ? null : l.ordersInvalidDate);
                                      if (valid) await m.load(date: date.text);
                                    }),
                          SbButton(
                              label: l.dashToday,
                              onPressed: m.busy
                                  ? null
                                  : () async {
                                      await m.load(today: true);
                                      if (mounted) {
                                        setState(() =>
                                            date.text = m.selectedDate ?? '');
                                      }
                                    }),
                        ]),
                        Text(l.dashScheduledInfo),
                        LayoutBuilder(builder: (ctx, c) {
                          final count = c.maxWidth >= 360 &&
                                      MediaQuery.textScalerOf(ctx).scale(14) <=
                                          20
                                  ? 2
                                  : 1,
                              width = (c.maxWidth - (count - 1) * 12) / count;
                          Widget tile(String label, String value, IconData icon,
                                  {VoidCallback? tap, String? hint}) =>
                              SizedBox(
                                  width: width,
                                  child: _Metric(
                                      label: label,
                                      value: value,
                                      icon: icon,
                                      onTap: tap,
                                      hint: hint));
                          return Wrap(spacing: 12, runSpacing: 12, children: [
                            tile(l.dashOrders, '${v.todayOrders}',
                                Icons.receipt_long_outlined,
                                tap: () => orders(m, 'ALL')),
                            tile(l.dashPending, '${v.pendingOrders}',
                                Icons.pending_actions,
                                tap: () => orders(m, 'PENDING')),
                            tile(l.dashCompleted, '${v.completedOrders}',
                                Icons.check_circle_outline,
                                tap: () => orders(m, 'DELIVERED')),
                            tile(l.dashSales, money(v.todaySalesPaise),
                                Icons.point_of_sale,
                                hint: l.dashReportsSoon),
                            tile(l.dashLifetime, money(v.totalEarningsPaise),
                                Icons.bar_chart,
                                hint: l.dashReportsSoon),
                            tile(
                                l.dashMilk,
                                l.dashLitres(
                                    dashboardLitres(v.milkStockLitres)),
                                Icons.inventory_2_outlined,
                                tap: () => open(m, '/vendor/dashboard-milk')),
                            tile(l.dashCustomers, '${v.activeCustomers}',
                                Icons.people_outline,
                                tap: () =>
                                    open(m, '/vendor/dashboard-customers')),
                          ]);
                        }),
                        Text(l.dashGrossInfo),
                        Text(l.dashCurrentInfo),
                        if (v.milkStockUnmeasuredProducts > 0)
                          Text(
                              l.dashUnknownMilk(v.milkStockUnmeasuredProducts)),
                        Text(l.dashActions,
                            style: Theme.of(context).textTheme.titleLarge),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          SbButton(
                              label: l.productsAdd,
                              onPressed: () => open(m, '/vendor/products/new')),
                          SbButton(
                              label: l.navOrders,
                              onPressed: () => orders(m, 'ALL')),
                          SbButton(
                              label: l.navCustomers,
                              onPressed: () =>
                                  const VendorCustomersRoute().go(context)),
                          SbButton(
                              label: l.khataPayments,
                              onPressed: () => open(m, '/vendor/payments')),
                          SbButton(
                              label: l.salesTitle,
                              onPressed: () => open(m, '/vendor/sales')),
                          SbButton(label: l.dashReports, onPressed: null),
                        ]),
                        Text(l.dashReportsSoon),
                      ] else if (!m.busy)
                        Text(l.dashNoCache),
                    ]))));
  }
}

class DashboardFeedback extends StatelessWidget {
  const DashboardFeedback({required this.model, super.key});
  final DashboardController model;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n, m = model;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (m.busy) const SbSkeleton(lines: 2),
      if (m.failure != null)
        Semantics(liveRegion: true, child: Text(m.failure!.toMessage(l))),
      if (m.metrics != null)
        Text(l.dashUpdated(dashboardUpdated(m.metrics!.serverTime))),
      if (m.stale && m.metrics != null) Text(l.dashOffline),
      if (m.cacheUnavailable) Text(l.dashCacheUnavailable),
      SbButton(label: l.authRetry, onPressed: m.busy ? null : m.load),
    ]);
  }
}

class DashboardBanners extends StatelessWidget {
  const DashboardBanners({required this.model, super.key});
  final DashboardController model;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n, m = model, status = m.plan?.status.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (m.metrics?.verified == false) ...[
        Text(l.dashVerification),
        SbButton(
            label: l.onboardingRefresh,
            onPressed: () =>
                const OnboardingRoute(OnboardingStep.status).go(context)),
      ],
      if (m.planUnavailable) Text(l.dashPlanUnavailable),
      if (status != null && status != 'ACTIVE') ...[
        Text(switch (status) {
          'EXPIRED' => l.dashPlanExpired,
          'SCHEDULED' => l.dashPlanScheduled,
          'UNASSIGNED' => l.dashPlanUnassigned,
          _ => l.dashPlanUnavailable
        }),
        Text(l.dashPlanSupport),
        SbButton(
            label: l.plansView, onPressed: () => context.push('/vendor/plans')),
      ]
    ]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label,
      required this.value,
      required this.icon,
      this.onTap,
      this.hint});
  final String label, value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? hint;
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$label: $value',
      button: onTap != null,
      onTap: onTap,
      child: ExcludeSemantics(
          child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 112),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon),
                                Text(label),
                                Text(value,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                if (hint != null) Text(hint!),
                              ])))))));
}

class VendorMorePage extends ConsumerStatefulWidget {
  const VendorMorePage({super.key});
  @override
  ConsumerState<VendorMorePage> createState() => _MoreState();
}

class _MoreState extends ConsumerState<VendorMorePage> {
  DashboardController? initialized;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(dashboardProvider), l = context.l10n;
    if (initialized != m) {
      initialized = m;
      if (m.metrics == null) Future.microtask(m.load);
    }
    Widget row(String text, String? path, {String? subtitle}) => ListTile(
        minVerticalPadding: 16,
        title: Text(text),
        subtitle: subtitle == null ? null : Text(subtitle),
        enabled: path != null,
        onTap: path == null
            ? null
            : () async {
                await context.push(path);
                await m.load();
              },
        trailing: path == null ? null : const Icon(Icons.chevron_right));
    return Scaffold(
        appBar: AppBar(title: Text(l.navMore)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      DashboardFeedback(model: m),
                      DashboardBanners(model: m),
                      row(l.khataTitle, '/vendor/khata'),
                      row(l.khataPayments, '/vendor/payments'),
                      row(l.salesTitle, '/vendor/sales'),
                      row(l.dashSubscriptions, '/vendor/subscriptions'),
                      row(l.dashDeliveries, '/vendor/deliveries'),
                      row(l.availabilityTitle, '/vendor/availability'),
                      row(l.areaTitle, const ServiceAreaRoute().location),
                      row(l.dashReports, null, subtitle: l.dashAvailableSoon),
                      row(l.dashPlans, '/vendor/plans'),
                      row(l.dashVendorSettings, null,
                          subtitle: l.dashAvailableSoon),
                      row(l.dashHelp, null, subtitle: l.dashAvailableSoon),
                      row(l.routeNotifications,
                          const CommonRoute(CommonPage.notifications).location),
                      row(l.dashAccountSettings,
                          const CommonRoute(CommonPage.settings).location),
                    ]))));
  }
}
