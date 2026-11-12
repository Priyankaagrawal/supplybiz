import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart'
    hide DiscoveryPage;
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/discovery/cart_controller.dart';
import 'package:supplybiz_mobile/features/discovery/favorites_controller.dart';
import 'package:supplybiz_mobile/features/discovery/discovery_controller.dart';
import 'package:supplybiz_mobile/features/discovery/discovery_page.dart';
import 'package:supplybiz_mobile/features/discovery/vendor_page.dart';
import 'package:supplybiz_mobile/features/discovery/product_page.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../home/home_test.dart' show manualLocation;
import '../addresses/addresses_test.dart' show reveal;
import 'discovery_fixture.dart';

NetworkClient discoveryClient(DiscoveryFixture f) => NetworkClient(
    baseUrl: 'https://api.example.test',
    session: TestSession(),
    adapter: f,
    delay: (_) async {});
Widget discoveryApp(
        {required CartController cart,
        required FavoritesController favorites,
        required VendorController vendor,
        DiscoveryController? list,
        Widget? child,
        double scale = 1}) =>
    ProviderScope(
        overrides: [
          cartProvider.overrideWith((ref) => cart),
          favoritesProvider.overrideWith((ref) => favorites),
          vendorProvider(vendorId).overrideWith((ref) => vendor),
          if (list != null)
            discoveryProvider((category: null, favorites: false))
                .overrideWith((ref) => list),
        ],
        child: MaterialApp(
            theme: sbLightTheme(const Locale('en')),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...SbLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: child ??
                const CustomerProductPage(
                    id: vendorId, productId: discoveryProductId)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'TC-204/205/210 forwards server sorting/location/category, deduplicates pages and clears denial',
      () async {
    final f = DiscoveryFixture(), client = discoveryClient(f);
    addTearDown(client.close);
    final m = DiscoveryController(DiscoveryApi(client.dio), manualLocation,
        (category: 'synthetic-category', favorites: false));
    addTearDown(m.dispose);
    await m.load();
    expect(m.items.single.id, vendorId);
    expect(f.calls.last.queryParameters['sort'], 'NEARBY');
    await m.load(more: true);
    expect(m.items, hasLength(1));
    expect(m.cursor, isNull);
    await m.load(order: 'POPULAR');
    expect(f.calls.last.queryParameters, containsPair('sort', 'POPULAR'));
    expect(f.calls.last.queryParameters, containsPair('pincode', '560001'));
    expect(f.calls.last.queryParameters,
        containsPair('category', 'synthetic-category'));
    f.denial = 403;
    await m.load();
    expect(m.items, isEmpty);
    expect(m.failure, isNotNull);
  });
  test(
      'TC-206/207 cart enforces MOQ/stock, requires vendor replacement, persists scoped intent and preserves on disk failure',
      () async {
    final f = DiscoveryFixture(),
        store = MemoryDrafts(),
        p = ProductResponse.fromJson(f.product),
        m = CartController(store, 'one:cart');
    addTearDown(m.dispose);
    await m.load();
    expect(await m.add(vendorId, 'Synthetic', p, 1), CartChange.invalid);
    expect(await m.add(vendorId, 'Synthetic', p, 13), CartChange.invalid);
    expect(await m.add(vendorId, 'Synthetic', p, 2), CartChange.saved);
    expect(m.count, 2);
    expect(await m.add(otherVendorId, 'Other', p, 2), CartChange.replaceVendor);
    expect(m.lines.single.vendorId, vendorId);
    store.fail = true;
    expect(await m.add(otherVendorId, 'Other', p, 2, replace: true),
        CartChange.unavailable);
    expect(m.lines.single.vendorId, vendorId);
    store.fail = false;
    expect(await m.add(otherVendorId, 'Other', p, 2, replace: true),
        CartChange.saved);
    final restored = CartController(store, 'one:cart'),
        other = CartController(store, 'two:cart');
    addTearDown(restored.dispose);
    addTearDown(other.dispose);
    await restored.load();
    await other.load();
    expect(restored.count, 2);
    expect(restored.lines.single.vendorId, otherVendorId);
    expect(other.count, 0);
    await restored.clear();
    expect(restored.count, 0);
  });
  test(
      'TC-208/209 favorites response-loss restart uses identical durable key/location and commits once',
      () async {
    final f = DiscoveryFixture(),
        client = discoveryClient(f),
        store = MemoryDrafts();
    addTearDown(client.close);
    final api = DiscoveryApi(client.dio);
    var m = FavoritesController(api, store, 'one:favorites', manualLocation);
    await m.load();
    f.loseResponse = true;
    await m.set(vendorId, true);
    expect(m.pending, isNotNull);
    expect(m.canEdit, isFalse);
    expect(f.commits, 1);
    final key = m.pending!['key'];
    m.dispose();
    m = FavoritesController(api, store, 'one:favorites', manualLocation);
    addTearDown(m.dispose);
    await m.load();
    expect(m.pending!['key'], key);
    await m.retry();
    expect(m.pending, isNull);
    expect(m.revision, 1);
    expect(f.commits, 1);
    expect(
        f.calls
            .where((r) => r.method == 'PUT')
            .map((r) => r.headers['Idempotency-Key'])
            .toSet(),
        {key});
    await m.set(vendorId, false);
    expect(f.favorite, isFalse);
    expect(f.calls.last.method, 'DELETE');
    expect(m.revision, 2);
  });
  test(
      'TC-209 expired favorite does not replay; refresh reads before clearing; disk failure never sends mutation',
      () async {
    final f = DiscoveryFixture(),
        client = discoveryClient(f),
        store = MemoryDrafts();
    addTearDown(client.close);
    final m = FavoritesController(
        DiscoveryApi(client.dio), store, 'one', manualLocation);
    addTearDown(m.dispose);
    await m.load();
    store.fail = true;
    await m.set(vendorId, true);
    expect(f.calls, isEmpty);
    expect(m.pending, isNotNull);
    store.fail = false;
    m.pending!['created'] = DateTime.now()
        .subtract(const Duration(hours: 25))
        .millisecondsSinceEpoch;
    await m.retry();
    expect(f.calls, isEmpty);
    expect(m.expired, isTrue);
    f.offline = true;
    await m.dismissExpired();
    expect(m.pending, isNotNull);
    f.offline = false;
    await m.dismissExpired();
    expect(m.pending, isNull);
    expect(f.calls.last.method, 'GET');
  });
  test(
      'TC-206/210 vendor denial removes product details and protected image failure returns no bytes',
      () async {
    final f = DiscoveryFixture(), client = discoveryClient(f);
    addTearDown(client.close);
    final m =
        VendorController(DiscoveryApi(client.dio), manualLocation, vendorId);
    addTearDown(m.dispose);
    await m.load();
    expect(m.about!.businessName, 'Synthetic discovery vendor');
    expect(await m.image('synthetic-private'), isNull);
    f.denial = 404;
    expect(await m.fresh(discoveryProductId), isNull);
    expect(m.about, isNull);
    expect(m.products, isEmpty);
  });
  test('disposed discovery never publishes a late request', () async {
    final f = DiscoveryFixture()..gate = Completer<void>(),
        client = discoveryClient(f);
    addTearDown(client.close);
    final m = DiscoveryController(DiscoveryApi(client.dio), manualLocation,
        (category: null, favorites: false));
    final result = m.load();
    await f.reached.future;
    m.dispose();
    f.gate!.complete();
    await result;
    expect(m.items, isEmpty);
  });
  testWidgets(
      'TC-206/207 MOQ stepper/cart badge at 200%; changed price requires review before add',
      (tester) async {
    final f = DiscoveryFixture(),
        client = discoveryClient(f),
        store = MemoryDrafts();
    addTearDown(client.close);
    final cart = CartController(store, 'cart'),
        fav = FavoritesController(
            DiscoveryApi(client.dio), store, 'fav', manualLocation),
        vendor = VendorController(
            DiscoveryApi(client.dio), manualLocation, vendorId);
    await cart.load();
    await fav.load();
    await tester.pumpWidget(
        discoveryApp(cart: cart, favorites: fav, vendor: vendor, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Quantity: 2'));
    expect(
        tester
            .widget<SbIconButton>(find.byWidgetPredicate((w) =>
                w is SbIconButton && w.semanticLabel == 'Decrease quantity'))
            .onPressed,
        isNull);
    f.product = {...f.product, 'version': 2, 'sellingPricePaise': 7000};
    await reveal(tester, find.text('Add to cart'));
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(cart.count, 0);
    expect(
        find.text(
            'Product details changed. Review the updated price and quantity before adding.'),
        findsOneWidget);
    await reveal(tester, find.text('Add to cart'));
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(cart.count, 2);
    expect(find.byType(Badge), findsOneWidget);
    expect(f.calls.where((r) => r.method != 'GET'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
      'TC-206 vendor Products/Subscription/About tabs render at 200% without reviews',
      (tester) async {
    final f = DiscoveryFixture(),
        client = discoveryClient(f),
        store = MemoryDrafts();
    addTearDown(client.close);
    final cart = CartController(store, 'cart'),
        fav = FavoritesController(
            DiscoveryApi(client.dio), store, 'fav', manualLocation),
        vendor = VendorController(
            DiscoveryApi(client.dio), manualLocation, vendorId);
    await cart.load();
    await fav.load();
    await tester.pumpWidget(discoveryApp(
        cart: cart,
        favorites: fav,
        vendor: vendor,
        scale: 2,
        child: const CustomerVendorPage(id: vendorId)));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Subscription'));
    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('View product'));
    expect(find.text('Reviews'), findsNothing);
    await reveal(tester, find.text('About'));
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    await reveal(tester, find.textContaining('Synthetic holiday'));
    expect(find.textContaining('Synthetic holiday'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
      'TC-204/205 list changes server sort and favorite mutation reloads list',
      (tester) async {
    final f = DiscoveryFixture(),
        client = discoveryClient(f),
        store = MemoryDrafts();
    addTearDown(client.close);
    final api = DiscoveryApi(client.dio);
    final cart = CartController(store, 'cart'),
        fav = FavoritesController(api, store, 'fav', manualLocation),
        vendor = VendorController(api, manualLocation, vendorId),
        list = DiscoveryController(
            api, manualLocation, (category: null, favorites: false));
    await cart.load();
    await fav.load();
    await tester.pumpWidget(discoveryApp(
        cart: cart,
        favorites: fav,
        vendor: vendor,
        list: list,
        child: const DiscoveryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Popular').last);
    await tester.pumpAndSettle();
    expect(list.sort, 'POPULAR');
    await reveal(tester, find.text('Add to favorites'));
    await tester.tap(find.text('Add to favorites'));
    await tester.pumpAndSettle();
    expect(f.favorite, isTrue);
    expect(find.text('Remove from favorites'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  test('malformed cart fails closed without exposing another owner', () async {
    final store = MemoryDrafts();
    store.rows['bad'] = {
      'lines': jsonEncode([
        {'qty': -1}
      ])
    };
    final m = CartController(store, 'bad');
    addTearDown(m.dispose);
    await m.load();
    expect(m.lines, isEmpty);
    expect(m.canEdit, isFalse);
    expect(m.failure, isNotNull);
  });
}
