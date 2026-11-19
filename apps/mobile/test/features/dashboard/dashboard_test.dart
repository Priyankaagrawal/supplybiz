import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/dashboard/dashboard_controller.dart';
import 'package:supplybiz_mobile/features/dashboard/dashboard_page.dart';
import 'package:supplybiz_mobile/features/dashboard/dashboard_destinations.dart';
import 'package:supplybiz_mobile/features/orders/orders_controller.dart';
import 'package:supplybiz_mobile/features/orders/order_date_queries.dart';
import 'package:supplybiz_mobile/features/products/products_controller.dart';
import 'package:supplybiz_mobile/features/products/products_page.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/addresses_test.dart' show reveal;
import '../orders/orders_test.dart' show OrdersFixture;

class DashboardFixture implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  bool offline = false, verified = true, photo = false, planFailure = false;
  String businessDate = '2026-11-19', planStatus = 'ACTIVE';
  int? denial;
  Completer<void>? gate, started;
  Map<String, dynamic> metrics(String day) => {
        'serverTime': '${businessDate}T01:30:00Z',
        'businessDate': businessDate,
        'date': day,
        'shopName': 'Synthetic dashboard shop',
        'city': 'Synthetic city',
        'shopPhotoMediaId':
            photo ? '11111111-1111-4111-8111-111111111111' : null,
        'verified': verified,
        'todayOrders': 5,
        'pendingOrders': 2,
        'completedOrders': 3,
        'todaySalesPaise': '45000',
        'totalEarningsPaise': '9007199254740993',
        'milkStockLitres': '123456789.125000',
        'milkStockUnmeasuredProducts': 1,
        'activeCustomers': 4,
      };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    ResponseBody json(Object data, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(data), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    if (denial != null) return json({'code': 'VENDOR_SUSPENDED'}, denial!);
    if (o.path.endsWith('/dashboard')) {
      started?.complete();
      await gate?.future;
      return json(
          metrics(o.queryParameters['date'] as String? ?? businessDate));
    }
    if (o.path.endsWith('/plan')) {
      return planFailure
          ? json({'code': 'UNAVAILABLE'}, 503)
          : json({
              'assignment': planStatus == 'ACTIVE'
                  ? {
                      'id': '11111111-1111-4111-8111-111111111111',
                      'planId': '22222222-2222-4222-8222-222222222222',
                      'code': 'BASIC',
                      'startsAt': '2026-11-01T00:00:00Z',
                      'endsAt': '2026-12-01T00:00:00Z'
                    }
                  : null,
              'status': planStatus,
              'customerLimit': 100,
              'activeCustomers': 4,
              'canAddCustomer': planStatus == 'ACTIVE',
              'features': [],
            });
    }
    return json({'code': 'MEDIA_UNAVAILABLE'}, 404);
  }
}

DashboardController model(DashboardFixture f, MemoryDrafts store,
        {String owner = 'synthetic:vendor:dashboard'}) =>
    DashboardController(
        NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: f,
            delay: (_) async {}),
        store,
        owner);
void closeModel(DashboardController m) {
  m.dispose();
  m.client.close();
}

Widget app(DashboardController m,
    {Widget? page,
    double scale = 1,
    GoRouter? router,
    List<Override> overrides = const []}) {
  Widget builder(BuildContext c, Widget? child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!);
  return ProviderScope(
      overrides: [dashboardProvider.overrideWith((ref) => m), ...overrides],
      child: router == null
          ? MaterialApp(
              theme: sbLightTheme(const Locale('en')),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...SbLocalizations.delegates
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              builder: builder,
              home: page ?? const VendorDashboardPage())
          : MaterialApp.router(
              theme: sbLightTheme(const Locale('en')),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...SbLocalizations.delegates
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              builder: builder,
              routerConfig: router));
}

Future<void> settle(WidgetTester t, DashboardController m) async {
  await t.runAsync(() async {
    for (var i = 0; i < 100 && m.busy; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));
  test(
      'TC-030 exact server metrics/calendar query, huge money and decimal litre grouping',
      () async {
    final f = DashboardFixture(), m = model(f, MemoryDrafts());
    addTearDown(() => closeModel(m));
    await m.load();
    expect(m.failure, isNull);
    expect(m.metrics!.todayOrders, 5);
    expect(m.metrics!.todaySalesPaise, '45000');
    expect(m.metrics!.totalEarningsPaise, '9007199254740993');
    expect(dashboardLitres(m.metrics!.milkStockLitres), '12,34,56,789.125');
    expect(dashboardLitres('0.000001'), '0.000001');
    expect(
        dashboardUpdated(DateTime.utc(2026, 11, 18, 20)), 'Nov 19, 2026 01:30');
    await m.load(date: '2026-10-01');
    expect(m.selectedDate, '2026-10-01');
    expect(
        f.calls
            .where((c) => c.path.endsWith('/dashboard'))
            .last
            .queryParameters,
        {'date': '2026-10-01'});
    await m.load(today: true);
    expect(m.todayMode, isTrue);
    expect(
        f.calls
            .where((c) => c.path.endsWith('/dashboard'))
            .last
            .queryParameters,
        isEmpty);
  });
  test(
      'TC-031 encrypted-cache boundary restores the last server Today; account/environment owners see no other cache',
      () async {
    final f = DashboardFixture(),
        store = MemoryDrafts(),
        first = model(f, store);
    await first.load();
    closeModel(first);
    f.offline = true;
    final restored = model(f, store),
        other =
            model(f, store, owner: 'other-env:other-account:VENDOR:dashboard');
    addTearDown(() => closeModel(restored));
    addTearDown(() => closeModel(other));
    await restored.load();
    await other.load();
    expect(restored.metrics!.todaySalesPaise, '45000');
    expect(restored.stale, isTrue);
    expect(restored.metrics!.serverTime, DateTime.utc(2026, 11, 19, 1, 30));
    expect(other.metrics, isNull);
    expect(other.plan, isNull);
    expect(jsonEncode(store.rows), isNot(contains('accessToken')));
  });
  test(
      'TC-031 missing offline date never relabels cached metrics; bounded cache retains fourteen successful dates',
      () async {
    final f = DashboardFixture(), store = MemoryDrafts(), m = model(f, store);
    addTearDown(() => closeModel(m));
    await m.load();
    f.offline = true;
    await m.load(date: '2026-01-01');
    expect(m.metrics, isNull);
    expect(m.selectedDate, '2026-01-01');
    f.offline = false;
    for (var day = 1; day <= 16; day++) {
      await m.load(date: '2026-10-${day.toString().padLeft(2, '0')}');
    }
    expect(jsonDecode(store.rows.values.single['metrics']!) as List,
        hasLength(14));
    f.offline = true;
    await m.load(date: '2026-10-01');
    expect(m.metrics, isNull);
    await m.load(date: '2026-10-16');
    expect(m.metrics, isNotNull);
  });
  test(
      'T-031 authorization denial clears identity, metrics, plan and cache; plan outage retains fresh metrics without old entitlements',
      () async {
    final f = DashboardFixture(), store = MemoryDrafts(), m = model(f, store);
    addTearDown(() => closeModel(m));
    await m.load();
    f.planFailure = true;
    await m.load();
    expect(m.metrics, isNotNull);
    expect(m.plan, isNull);
    expect(m.planUnavailable, isTrue);
    expect(m.stale, isFalse);
    f.denial = 403;
    await m.load();
    expect(m.metrics, isNull);
    expect(m.plan, isNull);
    expect(m.photo, isNull);
    expect(store.rows.values.single, isEmpty);
  });
  test(
      'T-031 cache failure preserves fresh reads and explicit offline-cache warning; invalid date sends nothing',
      () async {
    final f = DashboardFixture(),
        store = MemoryDrafts()..fail = true,
        m = model(f, store);
    addTearDown(() => closeModel(m));
    await m.load();
    expect(m.metrics, isNotNull);
    expect(m.cacheUnavailable, isTrue);
    expect(m.stale, isFalse);
    final count = f.calls.length;
    await m.load(date: '2026-02-30');
    expect(f.calls, hasLength(count));
  });
  test('T-031 disposal fences delayed reads and leaves no late cache write',
      () async {
    final f = DashboardFixture()
          ..gate = Completer<void>()
          ..started = Completer<void>(),
        store = MemoryDrafts(),
        m = model(f, store);
    final future = m.load();
    await f.started!.future;
    closeModel(m);
    f.gate!.complete();
    await future;
    expect(store.rows, isEmpty);
  });
  test(
      'T-031 Pending drill-down sends existing tab ONGOING and selected calendar date; changing to ALL removes it',
      () async {
    final f = OrdersFixture(),
        client = NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: f,
            delay: (_) async {});
    configureOrderDateQueries(client.dio);
    final m = VendorOrdersController(
        VendorOrdersApi(client.dio), MemoryDrafts(), 'synthetic-orders');
    addTearDown(() {
      m.dispose();
      client.close();
    });
    await m.load(filter: 'PENDING', day: DateTime(2026, 11, 19));
    final q = f.requests.last.queryParameters;
    expect(q['status'], 'ALL');
    expect(q['tab'], 'ONGOING');
    expect(q['date'], '2026-11-19');
    await m.load(filter: 'ALL');
    expect(f.requests.last.queryParameters.containsKey('tab'), isFalse);
  });
  testWidgets(
      'TC-030 dashboard renders exact tiles, verified/header and 200% text without overflow',
      (t) async {
    final f = DashboardFixture();
    late DashboardController m;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts());
      await m.load();
    });
    await t.pumpWidget(app(m, scale: 2));
    await settle(t, m);
    expect(find.text('Synthetic dashboard shop'), findsOneWidget);
    await reveal(t, find.text('Orders for date'));
    expect(find.text('Orders for date'), findsOneWidget);
    await reveal(t, find.text('Lifetime recorded sales'));
    expect(find.textContaining('9,00,71,99,25,47,409.93'), findsOneWidget);
    await reveal(t, find.text('12,34,56,789.125 L'));
    expect(find.text('12,34,56,789.125 L'), findsOneWidget);
    await reveal(t, find.text('Quick actions'));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'TC-031 saved offline data shows last updated IST; expiry/unverified banners never invent a purchase action',
      (t) async {
    final f = DashboardFixture()
          ..verified = false
          ..planStatus = 'EXPIRED',
        store = MemoryDrafts();
    late DashboardController m;
    await t.runAsync(() async {
      m = model(f, store);
      await m.load();
      f.offline = true;
    });
    await t.pumpWidget(app(m));
    await settle(t, m);
    expect(find.textContaining('Last updated Nov 19, 2026 07:00 IST'),
        findsOneWidget);
    expect(find.textContaining('Showing saved dashboard'), findsOneWidget);
    await reveal(t, find.textContaining('Your plan has expired'));
    expect(find.textContaining('Your plan has expired'), findsOneWidget);
    expect(find.textContaining('Buy'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets('T-031 pending tile navigates with exact selected date/filter',
      (t) async {
    final f = DashboardFixture();
    late DashboardController m;
    Uri? opened;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts());
      await m.load();
    });
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const VendorDashboardPage()),
      GoRoute(
          path: '/vendor/dashboard-orders',
          builder: (_, s) {
            opened = s.uri;
            return const Scaffold(body: Text('Synthetic destination'));
          })
    ]);
    await t.pumpWidget(app(m, router: router));
    await settle(t, m);
    await reveal(t, find.text('Pending orders'));
    await t.tap(find.text('Pending orders'));
    await t.pumpAndSettle();
    expect(
        opened!.queryParameters, {'date': '2026-11-19', 'filter': 'PENDING'});
    await t.pumpWidget(const SizedBox());
    router.dispose();
    m.client.close();
  });
  testWidgets(
      'T-031 More shows working active destinations, disables future UI and hides deferred staff/wallet/reviews',
      (t) async {
    final f = DashboardFixture();
    late DashboardController m;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts());
      await m.load();
    });
    await t.pumpWidget(app(m, page: const VendorMorePage(), scale: 2));
    await settle(t, m);
    await reveal(t, find.text('Reports'));
    final row = t.widget<ListTile>(find.ancestor(
        of: find.text('Reports'), matching: find.byType(ListTile)));
    expect(row.onTap, isNotNull); // T-102 now owns the Reports destination.
    await reveal(t, find.text('Plans'));
    final plansRow = t.widget<ListTile>(
        find.ancestor(of: find.text('Plans'), matching: find.byType(ListTile)));
    expect(plansRow.onTap, isNotNull);
    await reveal(t, find.text('Account and security'));
    expect(find.text('Account and security'), findsOneWidget);
    expect(find.text('Staff'), findsNothing);
    expect(find.text('Wallet'), findsNothing);
    expect(find.text('Reviews'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets('T-031 Add Product destination reuses the owned editor',
      (t) async {
    final f = DashboardFixture();
    late DashboardController m;
    late ProductsController p;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts());
      await m.load();
      p = ProductsController(
          NetworkClient(
              baseUrl: 'https://api.example.test',
              session: TestSession(),
              adapter: f,
              delay: (_) async {}),
          MemoryDrafts(),
          'synthetic-products')
        ..ready = true
        ..types = ['MILK'];
    });
    await t.pumpWidget(app(m,
        page: const DashboardProductNewPage(),
        overrides: [productsProvider.overrideWith((ref) => p)]));
    await t.pumpAndSettle();
    expect(find.byType(ProductEditor), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
    p.client.close();
  });
  testWidgets('T-031 milk stock drill-down shows only active milk products',
      (t) async {
    final f = DashboardFixture();
    late DashboardController m;
    late ProductsController p;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts());
      await m.load();
      p = ProductsController(
          NetworkClient(
              baseUrl: 'https://api.example.test',
              session: TestSession(),
              adapter: f,
              delay: (_) async {}),
          MemoryDrafts(),
          'synthetic-products')
        ..ready = true
        ..types = ['MILK', 'CURD'];
      p.products = [
        for (var i = 0; i < 3; i++)
          ProductResponse.fromJson({
            'id': '11111111-1111-4111-8111-11111111111$i',
            'name': [
              'Synthetic active milk',
              'Synthetic inactive milk',
              'Synthetic curd'
            ][i],
            'productType': i == 2 ? 'CURD' : 'MILK',
            'milkType': i == 2 ? null : 'COW',
            'unitValue': 1,
            'unitType': 'L',
            'sellingPricePaise': 5000,
            'subscriptionPricePaise': null,
            'stockQty': 2,
            'moq': 1,
            'description': '',
            'imageMediaId': null,
            'isActive': i != 1,
            'version': 1,
          })
      ];
    });
    await t.pumpWidget(app(m,
        page: const DashboardListPage(milk: true),
        overrides: [productsProvider.overrideWith((ref) => p)]));
    await t.pumpAndSettle();
    expect(find.text('Synthetic active milk'), findsOneWidget);
    expect(find.text('Synthetic inactive milk'), findsNothing);
    expect(find.text('Synthetic curd'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
    p.client.close();
  });
}
