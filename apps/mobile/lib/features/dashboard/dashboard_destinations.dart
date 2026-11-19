// T-031: reuse existing owned editors/lists without duplicating their mutations.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../products/products_controller.dart';
import '../products/products_page.dart';
import '../customers/customers_controller.dart';
import '../customers/customers_page.dart';

class DashboardListPage extends ConsumerStatefulWidget {
  const DashboardListPage({required this.milk, super.key});
  final bool milk;
  @override
  ConsumerState<DashboardListPage> createState() => _DashboardListState();
}

class _DashboardListState extends ConsumerState<DashboardListPage> {
  Object? initialized;
  @override
  Widget build(BuildContext context) {
    final Object model = widget.milk
        ? ref.watch(productsProvider)
        : ref.watch(customersProvider);
    if (initialized != model) {
      Future.microtask(() {
        if (!mounted) return;
        if (model is ProductsController) model.query('', 'MILK');
        if (model is CustomersController) model.query('', 'ACTIVE');
        if (mounted) setState(() => initialized = model);
      });
      return const Scaffold(body: SafeArea(child: SbSkeleton()));
    }
    return widget.milk
        ? const ProductsPage(activeOnly: true)
        : const CustomersPage();
  }
}

class DashboardProductNewPage extends ConsumerStatefulWidget {
  const DashboardProductNewPage({super.key});
  @override
  ConsumerState<DashboardProductNewPage> createState() =>
      _DashboardProductNewState();
}

class _DashboardProductNewState extends ConsumerState<DashboardProductNewPage> {
  String? editorOwner;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(productsProvider), l = context.l10n;
    if (m.canEdit && m.types.isNotEmpty) editorOwner = m.owner;
    if (editorOwner == m.owner) {
      return ProductEditor(key: ValueKey(m.owner), owner: m.owner);
    }
    return Scaffold(
        appBar: AppBar(title: Text(l.productsAdd)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          if (m.busy) const SbSkeleton(),
          if (m.failure != null) Text(m.failure!.toMessage(l)),
          if (m.cached) Text(l.productsOffline),
          if (m.pending != null) ...[
            Text(l.productsPending),
            SbButton(
                label: l.productsRetryPending,
                onPressed: m.busy ? null : m.retryPending)
          ],
          if (m.ready && m.types.isEmpty) Text(l.productsNoTypes),
          SbButton(label: l.authRetry, onPressed: m.busy ? null : m.load),
        ])));
  }
}
