import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/checkout/checkout_controller.dart';
import 'package:supplybiz_mobile/features/checkout/checkout_page.dart';
import 'package:supplybiz_mobile/features/checkout/new_order_page.dart';
import 'package:supplybiz_mobile/features/discovery/discovery_controller.dart';
import 'package:supplybiz_mobile/features/discovery/favorites_controller.dart';
import 'package:supplybiz_mobile/features/discovery/cart_controller.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/address_fixture.dart' show addressJson;
import '../addresses/addresses_test.dart' show reveal;
import '../discovery/discovery_test.dart' show discoveryApp, discoveryClient;
import '../discovery/discovery_fixture.dart' show DiscoveryFixture, vendorId;
import '../home/home_test.dart' show manualLocation;
import '../products/catalog_fixture.dart' show productJson, syntheticProductId;

const checkoutVendor = '55555555-5555-4555-8555-555555555555';

class CheckoutFixture implements HttpClientAdapter {
  final requests = <RequestOptions>[], keys = <String>{};
  bool lost = false, priceChange = false, offline = false, noSlots = false;
  int commits = 0;
  String? errorCode;
  Completer<void>? gate;
  Map<String, dynamic> bill = {
    'serverTime': '2026-11-13T10:00:00Z',
    'businessDate': '2026-11-13',
    'sameDayCutoff': null,
    'items': [
      {
        'productId': syntheticProductId,
        'name': 'Synthetic Cow Milk',
        'unitValue': '1',
        'unitType': 'L',
        'qty': 2,
        'unitPricePaise': '6010',
        'lineTotalPaise': '12020'
      }
    ],
    'subtotalPaise': '12020',
    'deliveryChargePaise': '0',
    'discountPaise': '0',
    'totalPaise': '12020',
  };
  Map<String, dynamic> get result => {
        'id': '77777777-7777-4777-8777-777777777777',
        'orderNo': 'ORD00000001',
        'vendorId': checkoutVendor,
        'status': 'NEW',
        'version': 1,
        'deliveryDate': '2026-11-14',
        'timeSlot': '07:00-08:00',
        'totalPaise': bill['totalPaise'],
        'paymentMode': 'POD_CASH',
        'paymentStatus': 'UNPAID',
        'source': 'APP',
        'createdAt': '2026-11-13T10:00:00Z'
      };
  ResponseBody reply(Object body, [int status = 200]) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions r, Stream<Uint8List>? stream, Future<void>? cancel) async {
    requests.add(r);
    if (gate != null) await gate!.future;
    if (offline) {
      throw DioException(
          requestOptions: r, type: DioExceptionType.connectionError);
    }
    if (r.path.endsWith('/addresses')) {
      return reply({
        'items': [addressJson()]
      });
    }
    if (r.path.endsWith('/options')) {
      return reply({
        'serverTime': '2026-11-13T10:00:00Z',
        'businessDate': '2026-11-13',
        'sameDayCutoff': null,
        'availableDates': ['2026-11-14', '2026-11-15'],
        'timeSlots': noSlots ? [] : ['07:00-08:00']
      });
    }
    if (r.path.endsWith('/quote')) return reply(bill, 201);
    if (errorCode != null) {
      return reply({'code': errorCode, 'productId': syntheticProductId}, 422);
    }
    if (priceChange) {
      priceChange = false;
      bill = {...bill, 'totalPaise': '13020', 'deliveryChargePaise': '1000'};
      return reply({'code': 'PRICE_CHANGED', 'quote': bill}, 409);
    }
    final key = r.headers['Idempotency-Key'] as String;
    if (keys.add(key)) commits++;
    if (lost) {
      lost = false;
      throw DioException(
          requestOptions: r, type: DioExceptionType.connectionError);
    }
    return reply(result, 201);
  }
}

NetworkClient checkoutClient(CheckoutFixture f) => NetworkClient(
    baseUrl: 'https://api.example.test',
    session: TestSession(),
    adapter: f,
    delay: (_) async {});
Future<CartController> checkoutCart(OnboardingDrafts store,
    {String owner = 'one:cart'}) async {
  final c = CartController(store, owner);
  await c.load();
  if (c.lines.isEmpty && c.canEdit) {
    await c.add(checkoutVendor, 'Synthetic shop',
        ProductResponse.fromJson(productJson()), 2);
  }
  return c;
}

Widget checkoutApp(CheckoutController m, {double scale = 1}) => ProviderScope(
        overrides: [
          checkoutProvider.overrideWith((ref) => m),
          cartProvider.overrideWith((ref) => m.cart)
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
            home: const CheckoutPage()));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'TC-220/227 same-key retry survives restart, locks cart before checkout opens, and saves result once',
      () async {
    final f = CheckoutFixture(),
        store = MemoryDrafts(),
        client = checkoutClient(f);
    addTearDown(client.close);
    var cart = await checkoutCart(store);
    var m = CheckoutController(CustomerOrdersApi(client.dio),
        CustomerAddressesApi(client.dio), cart, store, 'one:checkout');
    await m.load();
    expect(m.options!.availableDates, ['2026-11-14', '2026-11-15']);
    await m.refreshQuote();
    f.lost = true;
    await m.place();
    expect(m.pending, isNotNull);
    expect(cart.canEdit, isFalse);
    final key = m.pending!['key'];
    m.dispose();
    cart.dispose();
    cart = CartController(store, 'one:cart');
    await cart.load();
    expect(cart.canEdit, isFalse);
    m = CheckoutController(CustomerOrdersApi(client.dio),
        CustomerAddressesApi(client.dio), cart, store, 'one:checkout');
    await m.load();
    await m.retry();
    expect(m.pending, isNull);
    expect(m.result!.orderNo, 'ORD00000001');
    expect(f.commits, 1);
    expect(f.requests.last.headers['Idempotency-Key'], key);
    expect(cart.lines, isEmpty);
    await m.finish();
    expect(m.result, isNull);
    expect(cart.canEdit, isTrue);
    expect(await store.read('other:checkout'), isEmpty);
    m.dispose();
    cart.dispose();
  });
  test('TC-226 changed total requires explicit reconfirmation and a fresh key',
      () async {
    final f = CheckoutFixture(),
        store = MemoryDrafts(),
        client = checkoutClient(f);
    addTearDown(client.close);
    final cart = await checkoutCart(store);
    final m = CheckoutController(CustomerOrdersApi(client.dio),
        CustomerAddressesApi(client.dio), cart, store, 'one:checkout');
    addTearDown(m.dispose);
    addTearDown(cart.dispose);
    await m.load();
    await m.refreshQuote();
    f.priceChange = true;
    await m.place();
    expect(m.pending, isNull);
    expect(m.priceChanged, isTrue);
    expect(m.quote!.totalPaise, '13020');
    expect(f.commits, 0);
    final prior = f.requests.last.headers['Idempotency-Key'];
    await m.place();
    expect(f.commits, 1);
    expect(f.requests.last.headers['Idempotency-Key'], isNot(prior));
    expect(
        (jsonDecode(f.requests.last.data as String)
            as Map)['expectedTotalPaise'],
        '13020');
  });
  test(
      'TC-222/223 disk failure never sends; product errors unlock cart and stale quote cannot be placed',
      () async {
    final f = CheckoutFixture(),
        store = MemoryDrafts(),
        client = checkoutClient(f);
    addTearDown(client.close);
    final cart = await checkoutCart(store);
    final m = CheckoutController(CustomerOrdersApi(client.dio),
        CustomerAddressesApi(client.dio), cart, store, 'one:checkout');
    addTearDown(m.dispose);
    addTearDown(cart.dispose);
    await m.load();
    await m.refreshQuote();
    store.fail = true;
    await m.place();
    expect(f.commits, 0);
    expect(f.requests.where((r) => r.path.endsWith('/orders')), isEmpty);
    store.fail = false;
    f.errorCode = 'OUT_OF_STOCK';
    await m.retry();
    expect(m.productErrorId, syntheticProductId);
    expect(m.pending, isNull);
    expect(m.canPlace, isFalse);
    expect(cart.canEdit, isTrue);
    await m.load();
    await m.refreshQuote();
    await cart.quantity(syntheticProductId, 3);
    expect(m.quote, isNull);
    expect(m.canPlace, isFalse);
  });
  test('TC-227 double taps serialize and disposing prevents late state writes',
      () async {
    final f = CheckoutFixture(),
        store = MemoryDrafts(),
        client = checkoutClient(f);
    addTearDown(client.close);
    final cart = await checkoutCart(store);
    final m = CheckoutController(CustomerOrdersApi(client.dio),
        CustomerAddressesApi(client.dio), cart, store, 'one:checkout');
    await m.load();
    await m.refreshQuote();
    f.gate = Completer<void>();
    final first = m.place();
    await Future<void>.delayed(Duration.zero);
    await m.place();
    m.dispose();
    f.gate!.complete();
    await first;
    expect(f.commits, 1);
    expect(store.rows['one:checkout']!.containsKey('pending'), isTrue);
    expect(m.result, isNull);
    cart.dispose();
  });
  testWidgets(
      'TC-230 Milk/Water tabs and fresh-product MOQ add to the single-vendor cart',
      (tester) async {
    final f = DiscoveryFixture(),
        client = discoveryClient(f),
        store = MemoryDrafts();
    addTearDown(client.close);
    final cart = await checkoutCart(store),
        vendor = VendorController(
            DiscoveryApi(client.dio), manualLocation, vendorId),
        favorites = FavoritesController(
            DiscoveryApi(client.dio), store, 'favorite', manualLocation);
    addTearDown(favorites.dispose);
    await tester.pumpWidget(discoveryApp(
        cart: cart,
        favorites: favorites,
        vendor: vendor,
        child: const NewOrderPage(id: vendorId),
        scale: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Water Can'));
    await tester.pumpAndSettle();
    expect(find.byType(SbEmpty), findsOneWidget);
    await tester.tap(find.text('Milk & Dairy'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Add to cart'));
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(cart.count, 4);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-220/231 responsive 200% quote shows free delivery, POD choices and no credit/coupon',
      (tester) async {
    final f = CheckoutFixture(),
        client = checkoutClient(f),
        store = MemoryDrafts();
    addTearDown(client.close);
    late CheckoutController m;
    await tester.runAsync(() async {
      final cart = await checkoutCart(store);
      m = CheckoutController(CustomerOrdersApi(client.dio),
          CustomerAddressesApi(client.dio), cart, store, 'one:checkout');
      await m.load();
      await m.refreshQuote();
    });
    await tester.pumpWidget(checkoutApp(m, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Delivery charge: ₹0 (Free)'));
    expect(find.text('Add to Khata'), findsNothing);
    expect(find.text('Apply Coupon'), findsNothing);
    await reveal(tester, find.text('Place Order'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
