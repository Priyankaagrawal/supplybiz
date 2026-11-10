import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/onboarding_device.dart';
import 'package:supplybiz_mobile/features/products/products_controller.dart';
import 'package:supplybiz_mobile/features/products/products_page.dart';

import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import 'catalog_fixture.dart';

ProductsController productModel(CatalogFixture fixture, MemoryDrafts store,
    {String owner = 'synthetic-owner:products'}) {
  final client = NetworkClient(
      baseUrl: 'https://api.example.test',
      session: TestSession(),
      adapter: fixture,
      delay: (_) async {});
  addTearDown(client.close);
  final model = ProductsController(client, store, owner);
  addTearDown(model.dispose);
  return model;
}

Map<String, dynamic> newProduct() => Map.of(productJson())
  ..remove('id')
  ..remove('version');
Widget productApp(ProductsController model,
        {Widget child = const ProductsPage(), double scale = 1}) =>
    ProviderScope(
        overrides: [productsProvider.overrideWith((ref) => model)],
        child: MaterialApp(
            theme: sbLightTheme(const Locale('en')),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('TC-035/036 prices parse as exact integer paise with bounded input', () {
    expect(parseProductPaise('60.10'), 6010);
    expect(parseProductPaise('0.01'), 1);
    expect(parseProductPaise('0'), 0);
    expect(parseProductPaise('21474836.47'), 2147483647);
    for (final bad in [
      '1.001',
      '-1',
      '1e2',
      'NaN',
      '21474836.48',
      '1,000',
      ''
    ]) {
      expect(parseProductPaise(bad), isNull);
    }
  });
  test(
      'TC-037 caches every page, restores read-only offline snapshot, filters and isolates owners',
      () async {
    final api = CatalogFixture();
    for (var i = 1; i <= 101; i++) {
      api.entries.add(productJson(id: 'synthetic-$i', name: 'Synthetic $i'));
    }
    final store = MemoryDrafts(), model = productModel(api, store);
    await model.load();
    expect(model.products, hasLength(102));
    expect(model.types, contains('MILK'));
    expect(
        api.calls.where((r) => r.uri.path.endsWith('/products')), hasLength(2));
    api.offline = true;
    final restored = productModel(api, store);
    await restored.load();
    expect(restored.cached, isTrue);
    expect(restored.canEdit, isFalse);
    restored.query('Cow', 'MILK');
    expect(restored.visible.single.id, syntheticProductId);
    restored.query('Cow', 'PANEER');
    expect(restored.visible, isEmpty);
    final isolated = productModel(api, store, owner: 'other-owner:products');
    await isolated.load();
    expect(isolated.products, isEmpty);
  });
  test(
      'TC-035 interrupted committed create replays durable payload/key across recreation exactly once',
      () async {
    final api = CatalogFixture(),
        store = MemoryDrafts(),
        model = productModel(api, store);
    await model.load();
    api.failAfterCommit = true;
    await model.save(newProduct());
    expect(model.pending, isNotNull);
    expect(model.failure, isA<NetworkFailure>());
    final key = api.writes.single.headers['Idempotency-Key'];
    final restored = productModel(api, store);
    await restored.load();
    expect(restored.pending, isNotNull);
    await restored.retryPending();
    expect(restored.pending, isNull);
    expect(api.commits, 1);
    expect(api.writes.last.headers['Idempotency-Key'], key);
    expect(api.entries, hasLength(2));
    expect(jsonDecode(store.rows[model.owner]!['products']!) as List,
        hasLength(2));
  });
  test(
      'TC-032/036 edit clears nullable values, preserves stock, and sends no vendor identity',
      () async {
    final api = CatalogFixture(), model = productModel(api, MemoryDrafts());
    await model.load();
    final body = newProduct()
      ..remove('stockQty')
      ..['subscriptionPricePaise'] = null
      ..['imageMediaId'] = null
      ..['milkType'] = null
      ..['productType'] = 'PANEER';
    await model.save(body, id: syntheticProductId);
    expect(model.failure, isNull);
    expect(model.products.single.stockQty, 12);
    expect(model.products.single.subscriptionPricePaise, isNull);
    expect(model.products.single.milkType, isNull);
    final raw = api.writes.single.data;
    final request = raw is String ? jsonDecode(raw) as Map : raw as Map;
    expect(request.containsKey('stockQty'), isFalse);
    expect(request.containsKey('vendorId'), isFalse);
    expect(request.containsKey('milkType'), isTrue);
    expect(request['milkType'], isNull);
  });
  test(
      'TC-039/040 deletion conflicts preserve product; adjustments and confirmed deletion update cache',
      () async {
    final api = CatalogFixture(), model = productModel(api, MemoryDrafts());
    await model.load();
    api.inUse = true;
    await model.remove(syntheticProductId);
    expect(model.failure?.code, 'PRODUCT_IN_USE');
    expect(model.pending, isNull);
    expect(model.products, hasLength(1));
    await model.adjust(syntheticProductId, -2, 'Synthetic count');
    expect(model.products.single.stockQty, 10);
    api.inUse = false;
    await model.remove(syntheticProductId);
    expect(model.products, isEmpty);
  });
  test(
      'failed encrypted persistence prevents network mutation and can be retried safely',
      () async {
    final api = CatalogFixture(),
        store = MemoryDrafts(),
        model = productModel(api, store);
    await model.load();
    store.fail = true;
    await model.save(newProduct());
    expect(api.writes, isEmpty);
    expect(model.canEdit, isFalse);
    store.fail = false;
    await model.retryPending();
    expect(api.commits, 1);
    expect(model.pending, isNull);
  });
  test(
      'authorization denial purges cache and does not expose previous products offline',
      () async {
    final api = CatalogFixture(),
        store = MemoryDrafts(),
        model = productModel(api, store);
    await model.load();
    api.denial = 403;
    await model.load();
    expect(model.products, isEmpty);
    expect(store.rows[model.owner], isEmpty);
    api.denial = null;
    api.offline = true;
    final restored = productModel(api, store);
    await restored.load();
    expect(restored.products, isEmpty);
  });
  test(
      'late catalog response cannot persist into storage after account provider disposal',
      () async {
    final api = CatalogFixture()..listGate = Completer<void>(),
        store = MemoryDrafts();
    final client = NetworkClient(
        baseUrl: 'https://api.example.test',
        session: TestSession(),
        adapter: api,
        delay: (_) async {});
    addTearDown(client.close);
    final model = ProductsController(client, store, 'late-owner');
    final loading = model.load();
    await api.listReached.future;
    model.dispose();
    api.listGate!.complete();
    await loading;
    expect(store.rows, isEmpty);
  });
  testWidgets(
      'S-V-06 cached list/filter at 200% has semantics and disables mutation',
      (tester) async {
    final api = CatalogFixture(),
        store = MemoryDrafts(),
        model = productModel(api, store);
    await tester.runAsync(model.load);
    api.offline = true;
    await tester.runAsync(model.load);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(productApp(model, scale: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('Showing your saved catalog'), findsOneWidget);
    expect(
        tester
            .widget<SbButton>(find.widgetWithText(SbButton, 'Add product'))
            .onPressed,
        isNull);
    expect(find.bySemanticsLabel('Search products by name'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Synthetic Cow Milk'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Synthetic Cow Milk'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'S-V-07 validation, type change, private image upload and exact-price save',
      (tester) async {
    final api = CatalogFixture(), model = productModel(api, MemoryDrafts());
    await tester.runAsync(model.load);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            onboardingChannel,
            (call) async => call.method == 'pick'
                ? {'bytes': syntheticPng, 'pdf': false}
                : null);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(onboardingChannel, null));
    await tester.pumpWidget(productApp(model, scale: 2));
    await tester.pumpAndSettle();
    unawaited(tester.state<NavigatorState>(find.byType(Navigator)).push<void>(
        MaterialPageRoute(
            builder: (_) => ProductEditor(
                owner: model.owner, product: model.products.single))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('product-price')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(
        find.byKey(const ValueKey('product-price')), '60.10');
    await tester.enterText(
        find.byKey(const ValueKey('product-subscription')), '99');
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Save product'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(
        tester
            .widget<SbButton>(find.widgetWithText(SbButton, 'Save product'))
            .onPressed,
        isNull);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('product-subscription')), -200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(
        find.byKey(const ValueKey('product-subscription')), '');
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Choose product photo'), 200,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(
        tester.element(find.widgetWithText(SbButton, 'Choose product photo')),
        alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose product photo'));
    await tester.pumpAndSettle();
    expect(model.failure, isNull);
    expect(api.writes.last.uri.path, '/api/v1/media');
    await tester.scrollUntilVisible(find.text('Save product'), 200,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(
        tester.element(find.widgetWithText(SbButton, 'Save product')),
        alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save product'));
    await tester.pumpAndSettle();
    expect(api.entries.single['sellingPricePaise'], 6010);
    expect(api.entries.single['subscriptionPricePaise'], isNull);
    expect(api.entries.single['stockQty'], 12);
    expect(api.entries.single['imageMediaId'], syntheticProductId);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('S-V-07 interrupted photo upload keeps an online refresh action',
      (tester) async {
    final api = CatalogFixture(), model = productModel(api, MemoryDrafts());
    await tester.runAsync(model.load);
    api.offline = true;
    await tester
        .runAsync(() => model.upload(syntheticPng, 'synthetic-image-key'));
    expect(model.cached, isTrue);
    await tester.pumpWidget(productApp(model,
        child:
            ProductEditor(owner: model.owner, product: model.products.single)));
    await tester.pumpAndSettle();
    api.offline = false;
    await tester.tap(find.byKey(const ValueKey('products-editor-refresh')));
    await tester.pumpAndSettle();
    expect(model.canEdit, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('S-V-35 requires a nonzero whole-pack adjustment and a reason',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StockAdjustmentDialog(stock: 12))));
    await tester.tap(find.text('Apply adjustment'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Check the name'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).first, '-13');
    await tester.enterText(find.byType(TextFormField).last, 'Synthetic count');
    await tester.tap(find.text('Apply adjustment'));
    await tester.pumpAndSettle();
    expect(find.text('Adjust stock'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
