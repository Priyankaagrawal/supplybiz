// S-V-06 / S-V-07 / S-V-35 / T-027
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/app_failure.dart';
import '../../core/storage/onboarding_device.dart';
import 'products_controller.dart';

String productTypeLabel(AppLocalizations l, String code) => switch (code) {
      'ALL' => l.productsAll,
      'MILK' => l.productsMilk,
      'PANEER' => l.productsPaneer,
      'CURD' => l.productsCurd,
      'GHEE' => l.productsGhee,
      'OTHER' => l.productsOther,
      _ => code.replaceAll('_', ' '),
    };
String productFailure(AppLocalizations l, AppFailure failure) =>
    switch (failure.code) {
      'PRODUCT_IN_USE' => l.productsInUse,
      'INSUFFICIENT_STOCK' => l.productsInsufficient,
      _ => failure.toMessage(l),
    };

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(productsProvider), l = context.l10n;
    return Scaffold(
        appBar: AppBar(title: Text(l.productsTitle)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          if (model.busy) const LinearProgressIndicator(),
          if (model.failure != null)
            Semantics(
                liveRegion: true,
                child: Text(productFailure(l, model.failure!))),
          if (model.cached) Text(l.productsOffline),
          if (model.pending != null) ...[
            Text(l.productsPending),
            SbButton(
                label: l.productsRetryPending,
                onPressed: model.busy ? null : model.retryPending),
          ],
          SbButton(
              label: l.authRetry,
              variant: SbButtonVariant.secondary,
              onPressed: model.busy ? null : model.load),
          TextField(
              decoration: InputDecoration(labelText: l.productsSearch),
              maxLength: 120,
              onChanged: (value) => model.query(value, model.filter)),
          DropdownButtonFormField<String>(
              key: ValueKey(model.filter),
              initialValue: model.filter,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.productsFilter),
              items: [
                for (final type in {
                  'ALL',
                  ...model.types,
                  ...model.products.map((p) => p.productType)
                })
                  DropdownMenuItem(
                      value: type, child: Text(productTypeLabel(l, type)))
              ],
              onChanged: (value) {
                if (value != null) model.query(model.search, value);
              }),
          const SizedBox(height: 12),
          SbButton(
              label: l.productsAdd,
              onPressed: model.canEdit && model.types.isNotEmpty
                  ? () => _editor(context, model)
                  : null),
          if (model.ready && model.types.isEmpty) Text(l.productsNoTypes),
          if (model.ready && model.visible.isEmpty)
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.productsEmpty)),
          for (final product in model.visible)
            Card(
                key: ValueKey(product.id),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (product.imageMediaId != null)
                            ProductPhoto(
                                key: ValueKey(
                                    '${model.owner}:${product.imageMediaId}'),
                                id: product.imageMediaId!,
                                model: model),
                          Text(product.name,
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(
                              '${productTypeLabel(l, product.productType)} · ${product.unitValue} ${product.unitType.value}'),
                          Text(formatInr(product.sellingPricePaise)),
                          Text(l.productsStockValue(product.stockQty)),
                          Text(product.isActive
                              ? l.productsActive
                              : l.productsInactive),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            SbButton(
                                label: l.productsEdit,
                                onPressed: model.canEdit
                                    ? () => _editor(context, model, product)
                                    : null),
                            SbButton(
                                label: l.productsAdjust,
                                variant: SbButtonVariant.secondary,
                                onPressed: model.canEdit
                                    ? () => _adjust(context, model, product)
                                    : null),
                            SbButton(
                                label: l.productsDelete,
                                variant: SbButtonVariant.secondary,
                                onPressed: model.canEdit
                                    ? () => _delete(context, model, product.id)
                                    : null),
                          ]),
                        ]))),
        ])));
  }

  void _editor(BuildContext context, ProductsController model,
          [ProductResponse? product]) =>
      Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => ProductEditor(product: product, owner: model.owner)));
  static Future<void> _delete(
      BuildContext context, ProductsController model, String id) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(l.productsDelete),
                content: Text(l.productsDeleteConfirm),
                actions: [
                  SbButton(
                      label: l.productsCancel,
                      variant: SbButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context, false)),
                  SbButton(
                      label: l.productsDelete,
                      onPressed: () => Navigator.pop(context, true)),
                ]));
    if (confirmed == true && model.canEdit) await model.remove(id);
  }

  static Future<void> _adjust(BuildContext context, ProductsController model,
      ProductResponse product) async {
    final result = await showDialog<StockAdjustment>(
        context: context,
        builder: (_) => StockAdjustmentDialog(stock: product.stockQty));
    if (result != null && model.canEdit) {
      await model.adjust(product.id, result.delta, result.reason);
    }
  }
}

class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({required this.stock, super.key});
  final int stock;
  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final form = GlobalKey<FormState>();
  final delta = TextEditingController(), reason = TextEditingController();
  @override
  void dispose() {
    delta.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
        title: Text(l.productsAdjust),
        content: SingleChildScrollView(
            child: Form(
                key: form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(l.productsStockValue(widget.stock)),
                  TextFormField(
                      controller: delta,
                      decoration: InputDecoration(labelText: l.productsDelta),
                      keyboardType:
                          const TextInputType.numberWithOptions(signed: true),
                      validator: (text) {
                        final n = int.tryParse(text?.trim() ?? '');
                        return n != null &&
                                n != 0 &&
                                n.abs() <= 2147483647 &&
                                widget.stock + n >= 0 &&
                                widget.stock + n <= 2147483647
                            ? null
                            : l.productsInvalid;
                      }),
                  TextFormField(
                      controller: reason,
                      maxLength: 200,
                      decoration: InputDecoration(labelText: l.productsReason),
                      validator: (text) => (text ?? '').trim().isEmpty
                          ? l.productsInvalid
                          : null),
                ]))),
        actions: [
          SbButton(
              label: l.productsCancel,
              variant: SbButtonVariant.secondary,
              onPressed: () => Navigator.pop(context)),
          SbButton(
              label: l.productsApply,
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(
                      context,
                      StockAdjustment(
                          delta: int.parse(delta.text.trim()),
                          reason: reason.text.trim()));
                }
              }),
        ]);
  }
}

class ProductPhoto extends StatefulWidget {
  const ProductPhoto({required this.id, required this.model, super.key});
  final String id;
  final ProductsController model;
  @override
  State<ProductPhoto> createState() => _ProductPhotoState();
}

class _ProductPhotoState extends State<ProductPhoto> {
  late final Future<Uint8List> image = widget.model.image(widget.id);
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
      future: image,
      builder: (context, snapshot) => snapshot.hasData
          ? Image.memory(snapshot.data!,
              height: 120,
              fit: BoxFit.contain,
              semanticLabel: context.l10n.productsPhoto,
              errorBuilder: (_, __, ___) =>
                  Text(context.l10n.productsPhotoUnavailable))
          : Text(context.l10n.productsPhotoUnavailable));
}

class ProductEditor extends ConsumerStatefulWidget {
  const ProductEditor({required this.owner, this.product, super.key});
  final String owner;
  final ProductResponse? product;
  @override
  ConsumerState<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditor> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  String? type, imageId;
  String milk = 'COW', unit = 'L';
  bool active = true, picking = false;
  String? localError;
  (Uint8List, String)? pendingImage;
  String text(String name) => fields[name]!.text.trim();
  String price(int? n) =>
      n == null ? '' : '${n ~/ 100}.${(n % 100).toString().padLeft(2, '0')}';
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final values = {
      'name': p?.name ?? '',
      'unit': '${p?.unitValue ?? 1}',
      'price': price(p?.sellingPricePaise),
      'subscription': price(p?.subscriptionPricePaise),
      'stock': '${p?.stockQty ?? 0}',
      'moq': '${p?.moq ?? 1}',
      'description': p?.description ?? ''
    };
    for (final e in values.entries) {
      fields[e.key] = TextEditingController(text: e.value);
    }
    type = p?.productType;
    milk = p?.milkType ?? 'COW';
    unit = p?.unitType.value ?? 'L';
    active = p?.isActive ?? true;
    imageId = p?.imageMediaId;
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool valid() {
    final selling = parseProductPaise(text('price')),
        subscription = text('subscription').isEmpty
            ? null
            : parseProductPaise(text('subscription'));
    final size = num.tryParse(text('unit')),
        stock = int.tryParse(text('stock')),
        moq = int.tryParse(text('moq'));
    return type != null &&
        text('name').isNotEmpty &&
        text('name').length <= 120 &&
        size != null &&
        size.isFinite &&
        size > 0 &&
        size <= 999999999.999 &&
        RegExp(r'^\d+(?:\.\d{1,3})?$').hasMatch(text('unit')) &&
        selling != null &&
        selling > 0 &&
        (text('subscription').isEmpty ||
            subscription != null && subscription <= selling) &&
        stock != null &&
        stock >= 0 &&
        stock <= 2147483647 &&
        moq != null &&
        moq >= 1 &&
        moq <= 2147483647 &&
        text('description').length <= 500;
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final model = ref.read(productsProvider);
    if (!model.canEdit || model.owner != widget.owner) return;
    await model.save({
      'name': text('name'),
      'productType': type,
      'milkType': type == 'MILK' ? milk : null,
      'unitValue': num.parse(text('unit')),
      'unitType': unit,
      'sellingPricePaise': parseProductPaise(text('price')),
      'subscriptionPricePaise': text('subscription').isEmpty
          ? null
          : parseProductPaise(text('subscription')),
      if (widget.product == null) 'stockQty': int.parse(text('stock')),
      'moq': int.parse(text('moq')),
      'description': text('description'),
      'isActive': active,
      'imageMediaId': imageId
    }, id: widget.product?.id);
    if (mounted && model.failure == null && model.pending == null) {
      Navigator.pop(context);
    }
  }

  Future<void> choosePhoto() async {
    final model = ref.read(productsProvider);
    if (!model.canEdit || picking) return;
    setState(() {
      picking = true;
      localError = null;
    });
    try {
      if (pendingImage == null) {
        final file = await const OnboardingDevice().pick();
        if (!mounted || file == null) return;
        final bytes = file['bytes'] as Uint8List;
        if (file['pdf'] == true ||
            bytes.isEmpty ||
            bytes.length > 5 * 1024 * 1024) {
          setState(() => localError = context.l10n.productsPhotoOnly);
          return;
        }
        pendingImage = (bytes, const Uuid().v4());
      }
      final id = await model.upload(pendingImage!.$1, pendingImage!.$2);
      if (mounted && id != null) {
        setState(() {
          imageId = id;
          pendingImage = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => localError = context.l10n.productsPhotoOnly);
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(productsProvider), l = context.l10n;
    if (model.owner != widget.owner) {
      return Scaffold(body: Center(child: Text(l.networkUnauthorized)));
    }
    final enabled = model.canEdit && !picking;
    final current =
        model.products.where((p) => p.id == widget.product?.id).firstOrNull ??
            widget.product;
    Widget field(String key, String label,
            {bool numeric = false, int max = 120}) =>
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextFormField(
                key: ValueKey('product-$key'),
                controller: fields[key],
                enabled: enabled,
                onChanged: (_) => setState(() {}),
                maxLength: max,
                decoration: InputDecoration(
                    labelText: label, border: const OutlineInputBorder()),
                keyboardType: numeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                validator: (_) => valid() ? null : l.productsInvalid));
    Widget choice(String label, String value, Map<String, String> values,
            ValueChanged<String> select) =>
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: DropdownButtonFormField<String>(
                key: ValueKey('$label:$value'),
                initialValue: values.containsKey(value) ? value : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: label),
                items: [
                  for (final e in values.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value))
                ],
                onChanged: enabled
                    ? (v) {
                        if (v != null) setState(() => select(v));
                      }
                    : null));
    return Scaffold(
        appBar: AppBar(
            title:
                Text(widget.product == null ? l.productsAdd : l.productsEdit)),
        body: SafeArea(
            child: Form(
                key: form,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  if (model.busy || picking) const LinearProgressIndicator(),
                  if (model.failure != null)
                    Semantics(
                        liveRegion: true,
                        child: Text(productFailure(l, model.failure!))),
                  if (localError != null) Text(localError!),
                  if (model.cached) ...[
                    Text(l.productsOffline),
                    SbButton(
                        key: const ValueKey('products-editor-refresh'),
                        label: l.authRetry,
                        onPressed: model.busy ? null : model.load),
                  ],
                  if (model.pending != null) ...[
                    Text(l.productsPending),
                    SbButton(
                        label: l.productsRetryPending,
                        onPressed: model.busy
                            ? null
                            : () async {
                                await model.retryPending();
                                if (context.mounted &&
                                    model.failure == null &&
                                    model.pending == null) {
                                  Navigator.pop(context);
                                }
                              })
                  ],
                  field('name', l.productsName),
                  choice(
                      l.productsType,
                      type ?? '',
                      {
                        for (final t in {
                          ...model.types,
                          if (type != null) type!
                        })
                          t: productTypeLabel(l, t)
                      },
                      (v) => type = v),
                  if (type == 'MILK')
                    choice(
                        l.productsMilkType,
                        milk,
                        {
                          'COW': l.productsCow,
                          'BUFFALO': l.productsBuffalo,
                          'TONED': l.productsToned,
                          'DOUBLE_TONED': l.productsDoubleToned,
                          'FULL_CREAM': l.productsFullCream,
                          'OTHER': l.productsOther
                        },
                        (v) => milk = v),
                  Wrap(spacing: 8, children: [
                    for (final preset in [
                      (l.productsUnit250, '250', 'ML'),
                      (l.productsUnit500, '500', 'ML'),
                      (l.productsUnitLitre, '1', 'L')
                    ])
                      ChoiceChip(
                          label: Text(preset.$1),
                          selected:
                              text('unit') == preset.$2 && unit == preset.$3,
                          onSelected: enabled
                              ? (_) => setState(() {
                                    fields['unit']!.text = preset.$2;
                                    unit = preset.$3;
                                  })
                              : null),
                  ]),
                  field('unit', l.productsUnitValue, numeric: true),
                  choice(
                      l.productsUnitType,
                      unit,
                      {
                        for (final t in ['ML', 'L', 'G', 'KG', 'PCS']) t: t
                      },
                      (v) => unit = v),
                  field('price', l.productsSellingPrice, numeric: true),
                  field('subscription', l.productsSubscriptionPrice,
                      numeric: true),
                  if (widget.product == null)
                    field('stock', l.productsStock, numeric: true)
                  else ...[
                    Text(l.productsStockValue(current!.stockQty)),
                    SbButton(
                        label: l.productsAdjust,
                        variant: SbButtonVariant.secondary,
                        onPressed: enabled
                            ? () =>
                                ProductsPage._adjust(context, model, current)
                            : null),
                  ],
                  field('moq', l.productsMoq, numeric: true),
                  field('description', l.productsDescription, max: 500),
                  SwitchListTile(
                      title: Text(l.productsActive),
                      value: active,
                      onChanged:
                          enabled ? (v) => setState(() => active = v) : null),
                  if (imageId != null)
                    ProductPhoto(
                        key: ValueKey(imageId), id: imageId!, model: model),
                  SbButton(
                      label: l.productsChoosePhoto,
                      variant: SbButtonVariant.secondary,
                      onPressed: enabled ? choosePhoto : null),
                  if (imageId != null)
                    SbButton(
                        label: l.productsRemovePhoto,
                        variant: SbButtonVariant.secondary,
                        onPressed: enabled
                            ? () => setState(() => imageId = null)
                            : null),
                  SbButton(
                      label: l.productsSave,
                      onPressed: enabled && valid() ? save : null),
                  if (widget.product != null)
                    SbButton(
                        label: l.productsDelete,
                        variant: SbButtonVariant.destructive,
                        onPressed: enabled
                            ? () async {
                                await ProductsPage._delete(
                                    context, model, widget.product!.id);
                                if (context.mounted &&
                                    model.failure == null &&
                                    model.products.every(
                                        (p) => p.id != widget.product!.id)) {
                                  Navigator.pop(context);
                                }
                              }
                            : null),
                ]))));
  }
}
