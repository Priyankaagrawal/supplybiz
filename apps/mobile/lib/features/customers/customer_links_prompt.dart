// S-C-38 / T-053: customer Home checks registration matches and refreshes on resume.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../auth/session_controller.dart';
import '../home/home_controller.dart';
import 'customer_links_controller.dart';

class CustomerLinksPrompt extends ConsumerStatefulWidget {
  const CustomerLinksPrompt({super.key});
  @override
  ConsumerState<CustomerLinksPrompt> createState() =>
      _CustomerLinksPromptState();
}

class _CustomerLinksPromptState extends ConsumerState<CustomerLinksPrompt>
    with WidgetsBindingObserver {
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(sessionProvider).user?.activeRole?.value == 'CUSTOMER') {
      ref.read(customerLinksProvider).load();
    }
  }

  Future<void> refreshHome(CustomerLinksController model) async {
    if (mounted &&
        identical(model, ref.read(customerLinksProvider)) &&
        model.completed == 'ACCEPTED') {
      await ref.read(homeProvider).load();
    }
  }

  Future<void> decide(String id, String name, bool accept) async {
    final model = ref.read(customerLinksProvider), l = context.l10n;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(accept ? l.linkAccept : l.linkDecline),
                content: SingleChildScrollView(
                    child: Text(accept
                        ? l.linkConsent(name)
                        : l.linkDeclineConfirm(name))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.productsCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l.customersConfirm))
                ]));
    // A confirmation belongs only to the account/role that opened it.
    if (!mounted ||
        confirmed != true ||
        !identical(model, ref.read(customerLinksProvider))) {
      return;
    }
    await model.decide(id, accept);
    await refreshHome(model);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).user;
    if (user == null || user.activeRole?.value != 'CUSTOMER') {
      return const SizedBox.shrink();
    }
    final model = ref.watch(customerLinksProvider), l = context.l10n;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                      header: true,
                      child: Text(l.linkTitle,
                          style: Theme.of(context).textTheme.titleLarge)),
                  if (model.busy) const SbSkeleton(lines: 2),
                  if (model.failure != null)
                    Semantics(
                        liveRegion: true,
                        child: Text(model.failure!.toMessage(l))),
                  if (model.completed != null)
                    Semantics(
                        liveRegion: true,
                        child: Text(model.completed == 'ACCEPTED'
                            ? l.linkAccepted
                            : l.linkDeclined)),
                  if (model.pending != null) ...[
                    Text(model.pending!['action'] == 'accept'
                        ? l.linkPendingAccept
                        : l.linkPendingDecline),
                    SbButton(
                        label: l.customersRetrySaved,
                        onPressed: model.busy
                            ? null
                            : () async {
                                await model.retryPending();
                                await refreshHome(model);
                              }),
                  ],
                  if (model.ready &&
                      model.requests.isEmpty &&
                      model.pending == null &&
                      !model.stale)
                    Text(l.linkEmpty),
                  for (final row in model.requests) ...[
                    Text(row.businessName ?? l.homeVendor),
                    SbButton(
                        label: l.linkAccept,
                        onPressed: model.canDecide
                            ? () => decide(
                                row.id, row.businessName ?? l.homeVendor, true)
                            : null),
                    SbButton(
                        label: l.linkDecline,
                        variant: SbButtonVariant.secondary,
                        onPressed: model.canDecide
                            ? () => decide(
                                row.id, row.businessName ?? l.homeVendor, false)
                            : null),
                  ],
                  SbButton(
                      label: l.linkRefresh,
                      variant: SbButtonVariant.secondary,
                      onPressed: model.busy ? null : model.load),
                  if (model.requests.length < model.total)
                    SbButton(
                        label: l.linkMore,
                        onPressed:
                            model.busy || model.stale ? null : model.more),
                ])));
  }
}
