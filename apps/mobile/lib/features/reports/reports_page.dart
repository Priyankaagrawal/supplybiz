// T-102 / S-V-17 / US-090, US-091. CSV only; server business dates anchor presets.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../dashboard/dashboard_page.dart'
    show dashboardLitres, dashboardUpdated;
import '../subscriptions/vendor_subscriptions_pages.dart'
    show subscriptionMoney;
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionDate;
import 'reports_controller.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key, this.initialDate});
  final String? initialDate;
  @override
  ConsumerState<ReportsPage> createState() => _ReportsState();
}

class _ReportsState extends ConsumerState<ReportsPage> {
  ReportsController? initialized;
  final from = TextEditingController(), to = TextEditingController();
  String? validation, synced;
  @override
  void dispose() {
    from.dispose();
    to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(reportsProvider), l = context.l10n, s = m.summary;
    if (initialized != m) {
      initialized = m;
      if (m.summary == null || m.stale || widget.initialDate != null) {
        Future.microtask(
            () => m.load(from: widget.initialDate, to: widget.initialDate));
      }
    }
    if (s != null && synced != '${m.from}:${m.to}') {
      synced = '${m.from}:${m.to}';
      from.text = m.from!;
      to.text = m.to!;
    }
    final disabled = m.busy || m.exporting;
    String money(String value) => subscriptionMoney(l, BigInt.parse(value));
    Widget metric(String label, String value) => Padding(
        key: ValueKey('reports-metric-$label'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label),
          SelectableText(value, style: Theme.of(context).textTheme.titleLarge)
        ]));
    void preset(int kind) {
      final date = s!.businessDate;
      final day = DateTime.utc(date.year, date.month, date.day);
      final start = kind == 1
          ? day.subtract(Duration(days: day.weekday - 1))
          : DateTime.utc(day.year, day.month);
      m.load(from: subscriptionDate(start), to: subscriptionDate(day));
    }

    return Scaffold(
        appBar: AppBar(title: Text(l.dashReports)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (disabled) const SbSkeleton(lines: 2),
                      if (m.failure != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(m.failure!.toMessage(l))),
                      if (m.stale && s != null) Text(l.reportsOffline),
                      if (m.cacheUnavailable) Text(l.dashCacheUnavailable),
                      SbButton(
                          label: l.authRetry,
                          onPressed: disabled ? null : m.load),
                      Text(l.reportsRangeHelp),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        SbButton(
                            label: l.dashToday,
                            onPressed:
                                disabled ? null : () => m.load(today: true)),
                        SbButton(
                            label: l.reportsWeek,
                            onPressed: disabled || s == null || m.stale
                                ? null
                                : () => preset(1)),
                        SbButton(
                            label: l.reportsMonth,
                            onPressed: disabled || s == null || m.stale
                                ? null
                                : () => preset(2)),
                      ]),
                      TextField(
                          controller: from,
                          enabled: !disabled,
                          decoration:
                              InputDecoration(labelText: l.reportsFrom)),
                      TextField(
                          controller: to,
                          enabled: !disabled,
                          decoration: InputDecoration(
                              labelText: l.reportsTo, errorText: validation)),
                      SbButton(
                          label: l.dashApplyDate,
                          onPressed: disabled
                              ? null
                              : () {
                                  final valid =
                                      validReportRange(from.text, to.text);
                                  setState(() => validation =
                                      valid ? null : l.reportsInvalidRange);
                                  if (valid) {
                                    m.load(from: from.text, to: to.text);
                                  }
                                }),
                      if (s != null) ...[
                        Text(l.reportsSelected(m.from!, m.to!)),
                        Text(l.dashUpdated(dashboardUpdated(s.serverTime))),
                        Text(l.reportsBasis),
                        metric(l.reportsSales, money(s.totalSalesPaise)),
                        metric(l.reportsOrders, '${s.totalOrders}'),
                        metric(l.reportsDelivered, '${s.deliveredOrders}'),
                        metric(l.reportsCancelled, '${s.cancelledOrders}'),
                        metric(
                            l.reportsMilk, dashboardLitres(s.milkSoldLitres)),
                        if (s.milkSoldUnmeasuredLines > 0)
                          Text(l.reportsUnknownMilk(s.milkSoldUnmeasuredLines)),
                        metric(l.reportsEarnings, money(s.totalEarningsPaise)),
                        metric(l.reportsPending, money(s.pendingPaymentsPaise)),
                        metric(l.reportsActive, '${s.activeCustomers}'),
                        Text(l.reportsCurrent),
                        metric(
                            l.reportsProductTotal, money(s.productSalesPaise)),
                        metric(l.reportsCharges, money(s.deliveryChargesPaise)),
                        metric(l.reportsDiscount, money(s.discountPaise)),
                        metric(l.reportsGap, money(s.unitemizedSalesPaise)),
                      ] else if (!m.busy)
                        Text(l.reportsNoData),
                      if (m.locked) ...[
                        Text(l.reportsLocked),
                        SbButton(
                            label: l.plansView,
                            onPressed: () => context.push('/vendor/plans')),
                      ],
                      if (m.detailFailure != null && !m.locked)
                        Text(m.detailFailure!.toMessage(l)),
                      if (m.daily case final d?) ...[
                        Text(
                            d.bucket.value == 'WEEK'
                                ? l.reportsWeekly
                                : l.reportsDaily,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(l.reportsTableHint),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                                columns: [
                                  DataColumn(label: Text(l.reportsFrom)),
                                  DataColumn(label: Text(l.reportsTo)),
                                  DataColumn(label: Text(l.reportsSales))
                                ],
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: double.infinity,
                                rows: d.items
                                    .map((row) => DataRow(cells: [
                                          DataCell(
                                              Text(subscriptionDate(row.from))),
                                          DataCell(
                                              Text(subscriptionDate(row.to))),
                                          DataCell(Text(money(row.salesPaise)))
                                        ]))
                                    .toList())),
                      ],
                      if (m.products case final p?) ...[
                        Text(l.reportsProducts,
                            style: Theme.of(context).textTheme.titleLarge),
                        if (p.items.isEmpty) Text(l.reportsNoProducts),
                        Text(l.reportsProductCount(
                            m.offset + p.items.length, p.total)),
                        metric(l.reportsAllProducts,
                            money(p.totalProductSalesPaise)),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                                columns: [
                                  DataColumn(label: Text(l.reportsProduct)),
                                  DataColumn(label: Text(l.reportsPack)),
                                  DataColumn(label: Text(l.reportsQuantity)),
                                  DataColumn(label: Text(l.reportsSales))
                                ],
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: double.infinity,
                                rows: p.items
                                    .map((row) => DataRow(cells: [
                                          DataCell(SizedBox(
                                              width: 180,
                                              child: Text(row.name))),
                                          DataCell(Text(
                                              '${row.unitValue} ${row.unitType}')),
                                          DataCell(Text(row.quantityPacks)),
                                          DataCell(Text(money(row.salesPaise)))
                                        ]))
                                    .toList())),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          SbButton(
                              label: l.reportsPrevious,
                              onPressed: disabled || m.offset == 0
                                  ? null
                                  : () => m.page(m.offset - 20)),
                          SbButton(
                              label: l.reportsNext,
                              onPressed: disabled ||
                                      m.offset + p.items.length >= p.total
                                  ? null
                                  : () => m.page(m.offset + 20)),
                        ]),
                      ],
                      Text(l.reportsCsvHelp),
                      if (m.hasPending)
                        Text(l.reportsPendingExport(
                            m.pendingFrom!, m.pendingTo!)),
                      if (m.exportFailure != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(m.exportFailure!.toMessage(l))),
                      if (m.exportExpired) Text(l.reportsExportExpired),
                      if (m.chooserOpened) Text(l.reportsChooserOpened),
                      SbButton(
                          label: m.hasPending
                              ? l.reportsRetryCsv
                              : l.reportsShareCsv,
                          onPressed: disabled ||
                                  m.stale ||
                                  m.locked ||
                                  s == null ||
                                  m.exportExpired
                              ? null
                              : m.exportCsv),
                      if (m.canResetExport)
                        SbButton(
                            label: l.reportsNewCsv,
                            onPressed: disabled ? null : m.resetExport),
                    ]))));
  }
}
