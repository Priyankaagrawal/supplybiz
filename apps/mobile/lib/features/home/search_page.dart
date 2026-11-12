// S-C-03 / T-043: serviceable vendor/product-name search via the generated client.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import 'home_controller.dart';

class CustomerSearchPage extends ConsumerStatefulWidget {
  const CustomerSearchPage({this.category, super.key});
  final String? category;
  @override
  ConsumerState<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends ConsumerState<CustomerSearchPage> {
  final query = TextEditingController();
  HomeSearchController? initialized;
  String? owner;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider),
        model = ref.watch(homeSearchProvider(widget.category)),
        l = context.l10n;
    if (owner != home.owner) {
      owner = home.owner;
      query.clear();
    }
    if (initialized != model) {
      initialized = model;
      final initialQuery = query.text;
      Future.microtask(() => model.search(initialQuery));
    }
    return Scaffold(
        appBar: AppBar(title: Text(l.homeSearchTitle)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.homeSearchHint),
          SbButton(
              label: l.discoveryVendors,
              onPressed: () => CustomerDiscoveryRoute(category: widget.category)
                  .push<void>(context)),
          if (model.location == null) ...[
            Text(l.homeLocationRequired),
            SbButton(
                label: l.homeChooseLocation,
                onPressed: () =>
                    const CustomerLocationRoute().push<void>(context))
          ] else ...[
            TextField(
                key: const ValueKey('home-query'),
                controller: query,
                enabled: !model.busy,
                maxLength: 120,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                    labelText: l.homeSearchTitle,
                    border: const OutlineInputBorder()),
                onSubmitted: (value) => unawaited(model.search(value))),
            SbButton(
                label: l.homeSearchAction,
                onPressed: model.busy ? null : () => model.search(query.text)),
            if (model.busy) const SbSkeleton(),
            if (model.term.isEmpty && model.recent.isNotEmpty) ...[
              Semantics(header: true, child: Text(l.homeRecentSearches)),
              for (final term in model.recent)
                SbButton(
                    label: term,
                    variant: SbButtonVariant.secondary,
                    onPressed: model.busy
                        ? null
                        : () {
                            query.text = term;
                            unawaited(model.search(term));
                          }),
            ],
            if (model.failure != null) ...[
              Semantics(
                  liveRegion: true, child: Text(model.failure!.toMessage(l))),
              SbButton(
                  label: l.authRetry,
                  onPressed: model.busy ? null : () => model.search(query.text))
            ],
            SbButton(
                label: l.homeChooseLocation,
                variant: SbButtonVariant.secondary,
                onPressed: () =>
                    const CustomerLocationRoute().push<void>(context)),
            if (model.ready && model.items.isEmpty)
              SbEmpty(message: l.homeSearchEmpty),
            for (final row in model.items)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                                header: true,
                                child: Text(row.businessName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge)),
                            SbButton(
                                label: l.discoveryOpenVendor,
                                onPressed: () => CustomerVendorRoute(row.id)
                                    .push<void>(context)),
                            Text(l.homeDistance((row.distanceMeters / 1000)
                                .toStringAsFixed(1))),
                          ]))),
            if (model.hasMore)
              SbButton(
                  label: l.homeMoreVendors,
                  onPressed: model.busy
                      ? null
                      : () => model.search(model.term, more: true)),
          ],
        ])));
  }
}
