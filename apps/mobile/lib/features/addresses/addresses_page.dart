// S-C-28 / T-047
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import 'addresses_controller.dart';

class AddressFeedback extends StatelessWidget {
  const AddressFeedback({required this.model, this.onRetrySaved, super.key});
  final AddressesController model;
  final Future<void> Function()? onRetrySaved;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (model.busy) const SbSkeleton(lines: 2),
      if (model.failure != null)
        Semantics(
            liveRegion: true,
            child: Text(model.failure!.code == 'DEFAULT_ADDRESS_REQUIRED'
                ? l.addressDefaultRequired
                : model.failure!.toMessage(l))),
      if (model.stale) Text(l.addressStale),
      if (model.pending != null) ...[
        Text(model.retryExpired ? l.addressExpired : l.addressPending),
        if (!model.retryExpired)
          SbButton(
              label: l.customersRetrySaved,
              onPressed:
                  model.busy ? null : onRetrySaved ?? model.retryPending),
        if (model.retryExpired && model.ready && !model.stale)
          SbButton(
              label: l.addressDismiss,
              onPressed: model.busy
                  ? null
                  : () async {
                      if (await addressConfirm(
                              context, l.addressDismiss, l.addressExpired) &&
                          context.mounted) {
                        await model.dismissExpired();
                      }
                    }),
      ],
    ]);
  }
}

Future<bool> addressConfirm(
        BuildContext context, String title, String message) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(title),
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

class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(addressesProvider), l = context.l10n;
    return Scaffold(
        appBar: AppBar(title: Text(l.addressTitle)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: model.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      AddressFeedback(model: model),
                      SbButton(
                          label: l.authRetry,
                          variant: SbButtonVariant.secondary,
                          onPressed: model.busy ? null : model.load),
                      const SizedBox(height: 12),
                      SbButton(
                          label: l.addressAdd,
                          onPressed: model.canEdit
                              ? () => const CustomerAddressNewRoute()
                                  .push<void>(context)
                              : null),
                      if (model.ready && model.addresses.isEmpty)
                        SbEmpty(message: l.addressEmpty),
                      for (final row in model.addresses)
                        AddressCard(row: row, model: model),
                    ]))));
  }
}

class AddressCard extends StatelessWidget {
  const AddressCard({required this.row, required this.model, super.key});
  final AddressResponse row;
  final AddressesController model;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                      header: true,
                      child: Text(row.label,
                          style: Theme.of(context).textTheme.titleLarge)),
                  if (row.isDefault) Text(l.addressDefault),
                  Text([
                    row.line1,
                    row.line2,
                    row.landmark,
                    row.city,
                    row.state,
                    row.pincode
                  ].where((v) => v.isNotEmpty).join(', ')),
                  Text(l.addressCoordinates(
                      '${row.latitude}', '${row.longitude}')),
                  SbButton(
                      label: l.addressEdit,
                      variant: SbButtonVariant.secondary,
                      onPressed: model.canEdit
                          ? () => CustomerAddressEditRoute(row.id)
                              .push<void>(context)
                          : null),
                  if (!row.isDefault)
                    SbButton(
                        label: l.addressMakeDefault,
                        variant: SbButtonVariant.secondary,
                        onPressed: model.canEdit
                            ? () => model.makeDefault(row.id)
                            : null),
                  SbButton(
                      label: l.addressDelete,
                      variant: SbButtonVariant.secondary,
                      onPressed: model.canEdit
                          ? () async {
                              if (await addressConfirm(context, l.addressDelete,
                                      l.addressDeleteConfirm(row.label)) &&
                                  context.mounted) {
                                await model.remove(row.id);
                              }
                            }
                          : null),
                ])));
  }
}
