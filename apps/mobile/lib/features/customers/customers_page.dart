// S-V-12 / S-V-14 / T-029
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/app_failure.dart';
import '../../core/router/routes.dart';
import '../../core/storage/customer_device.dart';
import 'customers_controller.dart';

String customerFailure(AppLocalizations l, AppFailure f) => switch (f.code) {
      'DUPLICATE' => l.customersDuplicate,
      'PLAN_CUSTOMER_LIMIT' => l.customersLimitReached,
      'LINKED_MOBILE_IMMUTABLE' => l.customersLinkedMobile,
      _ => f.toMessage(l),
    };
String customerFilter(AppLocalizations l, String value) => switch (value) {
      'ACTIVE' => l.customersActive,
      'INACTIVE' => l.customersInactive,
      'SUBSCRIPTION' => l.customersSubscribed,
      _ => l.customersAll,
    };
String customerPayment(AppLocalizations l, String value) => switch (value) {
      'UPI' => l.customersUpi,
      'BANK' => l.customersBank,
      'WALLET' => l.customersWallet,
      _ => l.customersCash,
    };

class CustomerFeedback extends StatelessWidget {
  const CustomerFeedback({required this.model, this.onRetrySaved, super.key});
  final CustomersController model;
  final Future<void> Function()? onRetrySaved;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (model.busy) const SbSkeleton(lines: 2),
      if (model.failure != null)
        Semantics(
            liveRegion: true, child: Text(customerFailure(l, model.failure!))),
      if (model.cached) Text(l.customersOffline),
      if (model.pending != null) ...[
        Text(l.customersPending),
        SbButton(
            label: l.customersRetrySaved,
            onPressed: model.busy ? null : onRetrySaved ?? model.retryPending),
      ],
    ]);
  }
}

class CustomersPage extends ConsumerWidget {
  const CustomersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(customersProvider), l = context.l10n;
    final visible = model.visible;
    return Scaffold(
        appBar: AppBar(title: Text(l.navCustomers)),
        body: SafeArea(
          child: RefreshIndicator(
              onRefresh: model.load,
              child: NotificationListener<ScrollNotification>(
                  onNotification: (notice) {
                    if (notice.metrics.extentAfter < 120 &&
                        visible.length < model.filtered.length) {
                      model.more();
                    }
                    return false;
                  },
                  child: ListView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        CustomerFeedback(model: model),
                        SbButton(
                            label: l.authRetry,
                            variant: SbButtonVariant.secondary,
                            onPressed: model.busy ? null : model.load),
                        if (model.ready && model.customerLimit != null)
                          Text(l.customersCapacity(
                              model.activeCount, model.customerLimit!)),
                        TextField(
                            decoration:
                                InputDecoration(labelText: l.customersSearch),
                            maxLength: 120,
                            onChanged: (value) =>
                                model.query(value, model.filter)),
                        DropdownButtonFormField<String>(
                            initialValue: model.filter,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.customersFilter),
                            items: [
                              for (final value in [
                                'ALL',
                                'ACTIVE',
                                'SUBSCRIPTION',
                                'INACTIVE'
                              ])
                                DropdownMenuItem(
                                    value: value,
                                    child: Text(customerFilter(l, value)))
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                model.query(model.search, value);
                              }
                            }),
                        const SizedBox(height: 12),
                        SbButton(
                            label: l.customersAdd,
                            onPressed: model.canEdit
                                ? () => const VendorCustomerNewRoute()
                                    .push<void>(context)
                                : null),
                        if (!model.ready &&
                            !model.busy &&
                            model.failure == null)
                          const SbSkeleton(),
                        if (model.ready && visible.isEmpty)
                          SbEmpty(message: l.customersEmpty),
                        for (final customer in visible)
                          Card(
                              key: ValueKey(customer.id),
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Semantics(
                                            header: true,
                                            child: Text(customer.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge)),
                                        Text(customer.mobile),
                                        if (customer.address.isNotEmpty)
                                          Text(customer.address),
                                        Text(customerFilter(
                                            l, customer.status.value)),
                                        Text(customer.userId == null
                                            ? l.customersOfflineAccount
                                            : l.customersLinked),
                                        SbButton(
                                            label: l.customersView,
                                            variant: SbButtonVariant.secondary,
                                            onPressed: () =>
                                                VendorCustomerRoute(customer.id)
                                                    .push<void>(context)),
                                      ]))),
                        if (visible.length < model.filtered.length)
                          SbButton(
                              label: l.customersMore, onPressed: model.more),
                      ]))),
        ));
  }
}

class CustomerDetailPage extends ConsumerWidget {
  const CustomerDetailPage({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(customersProvider),
        l = context.l10n,
        customer = model.find(id);
    return Scaffold(
        appBar: AppBar(title: Text(l.customersDetail)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          CustomerFeedback(model: model),
          SbButton(
              label: l.authRetry,
              variant: SbButtonVariant.secondary,
              onPressed: model.busy ? null : model.load),
          if (customer == null) ...[
            if (!model.ready && model.failure == null) const SbSkeleton(),
            if (model.ready) Text(l.customersNotFound),
          ] else ...[
            Semantics(
                header: true,
                child: Text(customer.name,
                    style: Theme.of(context).textTheme.headlineSmall)),
            SelectableText(customer.mobile),
            Text(customerFilter(l, customer.status.value)),
            Text(customer.userId == null
                ? l.customersOfflineAccount
                : l.customersLinked),
            Text(customer.address.isEmpty
                ? l.customersNoAddress
                : customer.address),
            if (customer.email != null) Text(customer.email!),
            Text(
                '${l.customersPayment}: ${customerPayment(l, customer.preferredPayment.value)}'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              SbButton(
                  label: l.customersCall,
                  onPressed: () async {
                    final ok =
                        await const CustomerDevice().dial(customer.mobile);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.customersDialUnavailable)));
                    }
                  }),
              SbButton(
                  label: l.customersEdit,
                  variant: SbButtonVariant.secondary,
                  onPressed: model.canEdit
                      ? () => VendorCustomerEditRoute(id).push<void>(context)
                      : null),
              SbButton(
                  label: customer.status.value == 'ACTIVE'
                      ? l.customersDeactivate
                      : l.customersReactivate,
                  variant: SbButtonVariant.secondary,
                  onPressed: model.canEdit
                      ? () async {
                          final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialog) => AlertDialog(
                                      title: Text(l.customersStatusConfirm(
                                          customer.name)),
                                      content: Text(
                                          customer.status.value == 'ACTIVE'
                                              ? l.customersKeepHistory
                                              : l.customersCheckCapacity),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialog, false),
                                            child: Text(l.productsCancel)),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialog, true),
                                            child: Text(l.customersConfirm))
                                      ]));
                          if (confirmed == true &&
                              context.mounted &&
                              model.canEdit &&
                              identical(model, ref.read(customersProvider))) {
                            await model.save({
                              'status': customer.status.value == 'ACTIVE'
                                  ? 'INACTIVE'
                                  : 'ACTIVE'
                            }, id: id);
                          }
                        }
                      : null),
            ]),
            const SizedBox(height: 24),
            // T-029 explicitly leaves activity tabs unavailable until M2/M3.
            // Never invent zero financial totals or send Add Order to a placeholder.
            Text(l.customersActivityUnavailable),
            Tooltip(
                message: l.customersActivityUnavailable,
                child: SbButton(label: l.customersAddOrder, onPressed: null)),
            for (final label in [
              l.customersOrders,
              l.customersSubscriptions,
              l.customersPayments
            ])
              ExpansionTile(title: Text(label), children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l.customersActivityUnavailable))
              ]),
          ],
        ])));
  }
}
