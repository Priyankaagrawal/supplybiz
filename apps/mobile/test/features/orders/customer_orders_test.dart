import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/storage/customer_device.dart';
import 'package:supplybiz_mobile/features/discovery/cart_controller.dart';
import 'package:supplybiz_mobile/features/orders/customer_orders_controller.dart';
import 'package:supplybiz_mobile/features/orders/customer_orders_pages.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts;
import '../products/catalog_fixture.dart' show productJson;
import '../addresses/addresses_test.dart' show reveal;
import 'orders_test.dart' show OrdersFixture, ordersClient, orderId, orderPhone;

/// Simulated mobile HTTP; real ownership/stock/ledger coverage is API-side.
class CustomerOrdersFixture extends OrdersFixture {
  CustomerOrdersFixture() {
    for (final row in rows) {
      row['itemSummary'] = ['Synthetic milk × 2'];
    }
  }
  Map<String, dynamic> get preview => {
        'vendorId': rows.first['vendorId'],
        'vendorName': 'Synthetic vendor',
        'items': [
          {'qty': 2, 'product': productJson()..['sellingPricePaise'] = 7000}
        ],
        'unavailable': [
          {
            'productId': '22222222-2222-4222-8222-222222222222',
            'name': 'Synthetic removed',
            'reason': 'PRODUCT_UNAVAILABLE'
          }
        ]
      };
  @override
  Map<String, dynamic> detail(Map<String, dynamic> row) => {
        ...super.detail(row),
        'vendorMobile': orderPhone,
        'failReason':
            row['status'] == 'FAILED' ? 'Synthetic unavailable customer' : null
      };
  @override
  Future<ResponseBody> fetch(
      RequestOptions r, Stream<Uint8List>? stream, Future<void>? cancel) async {
    requests.add(r);
    if (gate != null) await gate!.future;
    if (offline) {
      throw DioException(
          requestOptions: r, type: DioExceptionType.connectionError);
    }
    if (denial != null) {
      return reply({'code': 'CUSTOMER_ROLE_REQUIRED'}, denial!);
    }
    if (r.method == 'GET' && r.path.endsWith('/orders')) {
      final tab = r.queryParameters['tab'];
      final selected = rows
          .where((o) => tab == 'ONGOING'
              ? ['NEW', 'ACCEPTED', 'PREPARING', 'OUT_FOR_DELIVERY']
                  .contains(o['status'])
              : tab == 'CANCELLED'
                  ? ['CANCELLED', 'REJECTED'].contains(o['status'])
                  : tab == 'DELIVERED'
                      ? o['status'] == 'DELIVERED'
                      : true)
          .toList();
      return reply({
        'items': selected
            .skip(r.queryParameters['offset'] as int? ?? 0)
            .take(20)
            .toList(),
        'total': selected.length
      });
    }
    final parts = r.path.split('/'),
        id = r.method == 'GET' ? parts.last : parts[parts.length - 2];
    final row = rows.where((o) => o['id'] == id).firstOrNull;
    if (row == null) return reply({'code': 'ORDER_NOT_FOUND'}, 404);
    if (r.method == 'GET') return reply(detail(row));
    if (r.path.endsWith('/reorder')) return reply(preview, 201);
    final key = r.headers['Idempotency-Key'] as String;
    if (replays.containsKey(key)) return reply(replays[key]!, 201);
    if (conflict) {
      conflict = false;
      row['status'] = 'ACCEPTED';
      row['version'] = 2;
      return reply({'code': 'VERSION_CONFLICT'}, 409);
    }
    row['status'] = 'CANCELLED';
    row['version'] = (row['version'] as int) + 1;
    commits++;
    replays[key] = Map.from(row);
    if (failAfterWrite) offline = true;
    if (lost) {
      lost = false;
      throw DioException(
          requestOptions: r, type: DioExceptionType.connectionError);
    }
    return reply(replays[key]!, 201);
  }
}

Widget customerOrdersApp(CustomerOrdersController m,
        {Widget? child, double scale = 1, CartController? cart}) =>
    ProviderScope(
        overrides: [
          customerOrdersProvider.overrideWith((ref) => m),
          cartProvider.overrideWith(
              (ref) => cart ?? CartController(MemoryDrafts(), 'test-cart'))
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
            home: child ?? const CustomerOrderPage(id: orderId)));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'TC-240 owned tabs/pagination/cache use customer endpoint and account isolation',
      () async {
    final f = CustomerOrdersFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    f.rows[1]['status'] = 'DELIVERED';
    f.rows[2]['status'] = 'REJECTED';
    var m = CustomerOrdersController(CustomerOrdersApi(http.dio), store, 'one');
    await m.load();
    expect(m.items.length, 20);
    await m.load(more: true);
    expect(m.items.length, 25);
    await m.load(filter: 'ONGOING');
    expect(m.total, 23);
    await m.load(filter: 'CANCELLED');
    expect(m.total, 1);
    expect(f.requests.last.queryParameters['tab'], 'CANCELLED');
    await m.open(orderId);
    m.dispose();
    f.offline = true;
    m = CustomerOrdersController(CustomerOrdersApi(http.dio), store, 'one');
    await m.load();
    expect(m.stale, isTrue);
    expect(m.details[orderId]!.vendorMobile, orderPhone);
    expect(m.canActOn(orderId), isFalse);
    final other =
        CustomerOrdersController(CustomerOrdersApi(http.dio), store, 'other');
    await other.load();
    expect(other.details, isEmpty);
    m.dispose();
    other.dispose();
  });
  test(
      'TC-242 durable exact cancellation survives response loss/restart and sends once on explicit retry',
      () async {
    final f = CustomerOrdersFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    var m = CustomerOrdersController(CustomerOrdersApi(http.dio), store, 'one');
    await m.open(orderId);
    f.lost = true;
    await m.cancel(orderId);
    final pending = Map.of(m.pending!);
    expect(f.commits, 1);
    m.dispose();
    m = CustomerOrdersController(CustomerOrdersApi(http.dio), store, 'one');
    await m.load();
    expect(m.pending, pending);
    expect(f.commits, 1);
    await m.retry();
    expect(f.commits, 1);
    expect(m.pending, isNull);
    expect(m.details[orderId]!.status, 'CANCELLED');
    final writes = f.requests.where((r) => r.path.endsWith('/cancel')).toList();
    expect(writes.length, 2);
    expect(writes[0].headers['Idempotency-Key'],
        writes[1].headers['Idempotency-Key']);
    expect(writes[0].data, writes[1].data);
    m.dispose();
  });
  test(
      'TC-243 conflict refresh blocks cancellation; disk failure sends nothing; permission denial wipes cache',
      () async {
    final f = CustomerOrdersFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    final m =
        CustomerOrdersController(CustomerOrdersApi(http.dio), store, 'one');
    await m.open(orderId);
    store.fail = true;
    await m.cancel(orderId);
    expect(f.commits, 0);
    expect(m.pending, isNotNull);
    store.fail = false;
    f.conflict = true;
    await m.retry();
    expect(m.pending, isNull);
    expect(m.details[orderId]!.status, 'ACCEPTED');
    await m.cancel(orderId);
    expect(f.commits, 0);
    f.denial = 403;
    await m.load();
    expect(m.details, isEmpty);
    expect(jsonDecode(store.rows['one']!['details']!), isEmpty);
    m.dispose();
  });
  test(
      'TC-241 trusted notice refresh updates active detail/list; disposed reads never persist',
      () async {
    final f = CustomerOrdersFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    final m =
        CustomerOrdersController(CustomerOrdersApi(http.dio), store, 'one');
    await m.open(orderId);
    f.rows.first['status'] = 'OUT_FOR_DELIVERY';
    await m.refreshFromNotice();
    expect(m.details[orderId]!.status, 'OUT_FOR_DELIVERY');
    expect(m.items.first.status, 'OUT_FOR_DELIVERY');
    final saved = Map.of(store.rows['one']!);
    f.gate = Completer<void>();
    final read = m.open(orderId);
    await Future<void>.delayed(Duration.zero);
    m.dispose();
    f.gate!.complete();
    await read;
    expect(store.rows['one'], saved);
  });
  test(
      'TC-244 reorder merges current-price products atomically, confirms vendor replacement and respects checkout lock',
      () async {
    final f = CustomerOrdersFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    f.rows.first['status'] = 'DELIVERED';
    final m =
        CustomerOrdersController(CustomerOrdersApi(http.dio), store, 'one');
    await m.open(orderId);
    final p = (await m.reorder(orderId))!;
    expect(p.unavailable.single.name, 'Synthetic removed');
    final cart = CartController(store, 'cart');
    await cart.load();
    expect(await cart.addReorder(p), CartChange.saved);
    expect(cart.lines.single.product.sellingPricePaise, 7000);
    expect(await cart.addReorder(p), CartChange.saved);
    expect(cart.lines.single.qty, 4);
    final other = OrderReorder(
        vendorId: 'other',
        vendorName: 'Other',
        items: p.items,
        unavailable: []);
    expect(await cart.addReorder(other), CartChange.replaceVendor);
    expect(cart.lines.single.vendorId, p.vendorId);
    cart.lockCheckout(true);
    expect(await cart.addReorder(other, replace: true), CartChange.unavailable);
    cart.lockCheckout(false);
    expect(await cart.addReorder(other, replace: true), CartChange.saved);
    expect(cart.lines.single.qty, 2);
    store.fail = true;
    expect(await cart.addReorder(p, replace: true), CartChange.unavailable);
    expect(cart.lines.single.vendorId, 'other');
    cart.dispose();
    m.dispose();
  });
  testWidgets(
      'TC-241/245 tracking, failure reason, vendor dialer and 200% layout',
      (tester) async {
    final f = CustomerOrdersFixture(), http = ordersClient(f);
    addTearDown(http.close);
    f.rows.first['status'] = 'FAILED';
    final m = CustomerOrdersController(
        CustomerOrdersApi(http.dio), MemoryDrafts(), 'one');
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerDeviceChannel, (c) async {
      call = c;
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerDeviceChannel, null));
    await tester.pumpWidget(customerOrdersApp(m, scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('Failed'), findsWidgets);
    await reveal(tester, find.text('Call vendor'));
    await tester.tap(find.text('Call vendor'));
    await tester.pump();
    expect(call?.arguments, {'mobile': orderPhone});
    await reveal(tester, find.text('Synthetic unavailable customer'));
    expect(find.text('Cancel order'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('TC-240 history cards/tabs render at 200%', (tester) async {
    final f = CustomerOrdersFixture(), http = ordersClient(f);
    addTearDown(http.close);
    final m = CustomerOrdersController(
        CustomerOrdersApi(http.dio), MemoryDrafts(), 'one');
    await tester.pumpWidget(
        customerOrdersApp(m, child: const CustomerOrdersPage(), scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('ORD00000001'), findsOneWidget);
    expect(find.textContaining('Synthetic milk × 2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
