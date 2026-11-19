import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/plans/plans_controller.dart';
import 'package:supplybiz_mobile/features/plans/plans_page.dart';
import 'package:supplybiz_mobile/features/notifications/notifications_controller.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/addresses_test.dart' show reveal;
import '../notifications/notification_fixture.dart' show notificationJson;

const commonFeatures = [
  'BASIC_ORDER_MANAGEMENT',
  'QUICK_SALE',
  'KHATA',
  'PAYMENT_RECORDS',
  'BASIC_REPORTS'
];

class PlansFixture implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  bool offline = false, empty = false;
  int? currentError, catalogError;
  String status = 'ACTIVE', code = 'BASIC';
  int count = 4, cap = 100;
  bool canAdd = true;
  Completer<void>? gate, started;
  Map<String, dynamic> get current => {
        'assignment': status == 'UNASSIGNED'
            ? null
            : {
                'id': '11111111-1111-4111-8111-111111111111',
                'planId': '22222222-2222-4222-8222-222222222222',
                'code': code,
                'startsAt': '2020-01-01T00:00:00Z',
                'endsAt': '2020-02-01T00:00:00Z'
              },
        'status': status,
        'customerLimit': cap,
        'activeCustomers': count,
        'canAddCustomer': canAdd,
        'features': status == 'ACTIVE' ? commonFeatures : [],
      };
  List<Map<String, dynamic>> get catalog => empty
      ? []
      : [
          for (final row in [
            ("BASIC", 100),
            ("STANDARD", 250),
            ("BUSINESS", 500),
            ("PREMIUM", 1000)
          ])
            {
              'id':
                  '${row.$2.toString().padLeft(8, '0')}-1111-4111-8111-111111111111',
              'code': row.$1,
              'name': row.$1,
              'updatedAt': '2026-11-19T01:00:00Z',
              'customerLimit': row.$2,
              'features': [
                ...commonFeatures,
                if (row.$1 != 'BASIC') 'SUBSCRIPTIONS',
                if (['BUSINESS', 'PREMIUM'].contains(row.$1)) 'ADVANCED_REPORTS'
              ],
              'isPopular': row.$1 == 'BUSINESS',
              'status': 'ACTIVE',
              'prices': [
                {'duration': 'MONTHLY', 'pricePaise': 20000},
                {'duration': 'HALF_YEARLY', 'pricePaise': 100000},
                {'duration': 'YEARLY', 'pricePaise': 190000}
              ]
            }
        ];
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    ResponseBody json(Object value, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(value), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    if (o.path.endsWith('/plan')) {
      started?.complete();
      await gate?.future;
      return currentError == null
          ? json(current)
          : json({
              'code': currentError == 403 ? 'VENDOR_SUSPENDED' : 'UNAVAILABLE'
            }, currentError!);
    }
    return catalogError == null
        ? json({'items': catalog})
        : json({'code': 'UNAVAILABLE'}, catalogError!);
  }
}

PlansController model(PlansFixture f, MemoryDrafts store,
        {String owner = 'synthetic-env:account:VENDOR:plans'}) =>
    PlansController(
        NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: f,
            delay: (_) async {}),
        store,
        owner);
void closeModel(PlansController m) {
  m.dispose();
  m.client.close();
}

Widget app(PlansController m, {double scale = 1}) => ProviderScope(
    overrides: [plansProvider.overrideWith((ref) => m)],
    child: MaterialApp(
        theme: sbLightTheme(const Locale('en')),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...SbLocalizations.delegates
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (c, child) => MediaQuery(
            data:
                MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: const PlansPage()));
Future<void> settle(WidgetTester t, PlansController m) async {
  await t.runAsync(() async {
    for (var n = 0; n < 100 && m.busy; n++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));
  test(
      'TC-120/124 generated GETs show server catalog/caps/features; status is never inferred from device date or price',
      () async {
    final f = PlansFixture(), m = model(f, MemoryDrafts());
    addTearDown(() => closeModel(m));
    await m.load();
    expect(m.current!.status.value, 'ACTIVE');
    expect(m.current!.assignment!.endsAt, DateTime.utc(2020, 2, 1));
    expect(m.catalog.map((p) => p.customerLimit), [100, 250, 500, 1000]);
    expect(m.catalog.singleWhere((p) => p.isPopular).code.value, 'BUSINESS');
    expect(m.current!.features, commonFeatures);
    expect(m.catalog.first.prices.first.pricePaise, 20000);
    expect(f.calls.map((c) => c.path),
        ['/api/v1/vendor/plan', '/api/v1/vendor/plans']);
    expect(f.calls.every((c) => c.method == 'GET'), isTrue);
    expect(planValidity(DateTime.utc(2020, 1, 1)), 'Jan 1, 2020 05:30');
  });
  test(
      'T-105 cached current/catalog remain visibly stale offline; owners cannot read another account/environment',
      () async {
    final f = PlansFixture(), store = MemoryDrafts(), first = model(f, store);
    await first.load();
    closeModel(first);
    f.offline = true;
    final restored = model(f, store),
        other = model(f, store, owner: 'other-env:other-user:CUSTOMER:plans');
    addTearDown(() => closeModel(restored));
    addTearDown(() => closeModel(other));
    await restored.load();
    await other.load();
    expect(restored.current!.customerLimit, 100);
    expect(restored.currentStale, isTrue);
    expect(restored.catalogStale, isTrue);
    expect(restored.catalog, hasLength(4));
    expect(other.current, isNull);
    expect(other.catalog, isEmpty);
  });
  test(
      'TC-125 partial catalog failure keeps new server expiry, not old ACTIVE state; refresh updates entitlements',
      () async {
    final f = PlansFixture(), m = model(f, MemoryDrafts());
    addTearDown(() => closeModel(m));
    await m.load();
    f.status = 'EXPIRED';
    f.canAdd = false;
    f.catalogError = 503;
    await m.load();
    expect(m.current!.status.value, 'EXPIRED');
    expect(m.current!.features, isEmpty);
    expect(m.currentStale, isFalse);
    expect(m.catalogStale, isTrue);
    expect(m.catalog, hasLength(4));
    f.currentError = 503;
    f.catalogError = null;
    await m.load();
    expect(m.currentStale, isTrue);
    expect(m.catalogStale, isFalse);
    f.currentError = null;
    f.status = 'ACTIVE';
    f.code = 'STANDARD';
    f.cap = 250;
    f.canAdd = true;
    await m.load();
    expect(m.current!.customerLimit, 250);
    expect(m.currentStale, isFalse);
  });
  test(
      'T-105 denial from either owned read clears all cached private assignment data',
      () async {
    for (final catalogDenied in [false, true]) {
      final f = PlansFixture(), store = MemoryDrafts(), m = model(f, store);
      await m.load();
      if (catalogDenied) {
        f.catalogError = 403;
      } else {
        f.currentError = 403;
      }
      await m.load();
      expect(m.current, isNull);
      expect(m.catalog, isEmpty);
      expect(store.rows.values.single, isEmpty);
      closeModel(m);
    }
  });
  test(
      'T-105 storage failure does not fabricate network freshness or entitlements',
      () async {
    final f = PlansFixture(),
        store = MemoryDrafts()..fail = true,
        m = model(f, store);
    addTearDown(() => closeModel(m));
    await m.load();
    expect(m.cacheUnavailable, isTrue);
    expect(m.currentStale, isFalse);
    expect(m.catalogStale, isFalse);
    expect(m.current!.canAddCustomer, isTrue);
    f.offline = true;
    await m.load();
    expect(m.currentStale, isTrue);
    expect(m.catalogStale, isTrue);
  });
  test(
      'T-105 disposal fences in-flight current read and does not persist or fetch catalog',
      () async {
    final f = PlansFixture()
          ..gate = Completer<void>()
          ..started = Completer<void>(),
        store = MemoryDrafts(),
        m = model(f, store);
    final loading = m.load();
    await f.started!.future;
    closeModel(m);
    f.gate!.complete();
    await loading;
    expect(store.rows, isEmpty);
    expect(f.calls, hasLength(1));
  });
  test(
      'TC-123 reminder destinations require owned vendor plan type and exact implemented path',
      () {
    InboxItem item(String role, String type, String path) =>
        InboxItem.fromJson(notificationJson(role: role)
          ..['type'] = type
          ..['path'] = path);
    for (final type in ['PLAN_EXPIRING', 'PLAN_EXPIRED']) {
      expect(notificationLocation(item('VENDOR', type, '/vendor/plans')),
          '/vendor/plans');
    }
    expect(
        notificationLocation(item('CUSTOMER', 'PLAN_EXPIRED', '/vendor/plans')),
        '/common/notifications');
    expect(notificationLocation(item('VENDOR', 'ORDER_NEW', '/vendor/plans')),
        '/common/notifications');
    expect(
        notificationLocation(
            item('VENDOR', 'PLAN_EXPIRED', '/vendor/plans/evil')),
        '/common/notifications');
  });
  testWidgets(
      'TC-124 catalog/current screen at 200% shows reference prices, limits, popular tier and no purchase/invoice action',
      (t) async {
    final f = PlansFixture();
    late PlansController m;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts());
      await m.load();
    });
    await t.pumpWidget(app(m, scale: 2));
    await settle(t, m);
    await reveal(t, find.text('Active'));
    expect(find.text('Active'), findsOneWidget);
    await reveal(t, find.text('Active customers: 4 / 100'));
    expect(find.text('Active customers: 4 / 100'), findsOneWidget);
    await reveal(t, find.text('Available plan tiers'));
    expect(find.text('Available plan tiers'), findsOneWidget);
    await reveal(t, find.text('Most popular'));
    expect(find.text('Most popular'), findsOneWidget);
    expect(find.textContaining('Monthly: ₹200.00'), findsWidgets);
    expect(find.text('Buy'), findsNothing);
    expect(find.text('Checkout'), findsNothing);
    expect(find.textContaining('Invoice'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'TC-125/126 expired and over-cap downgrade retains records and shows server customer-growth denial',
      (t) async {
    final f = PlansFixture()
      ..status = 'EXPIRED'
      ..count = 150
      ..cap = 100
      ..canAdd = false;
    late PlansController m;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts());
      await m.load();
    });
    await t.pumpWidget(app(m));
    await settle(t, m);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.textContaining('active customer limit has been reached'),
        findsOneWidget);
    await reveal(
        t,
        find.textContaining(
            'Your existing customers and history are retained'));
    expect(
        find.textContaining('Your existing customers and history are retained'),
        findsOneWidget);
    expect(f.calls.every((c) => c.method == 'GET'), isTrue);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'TC-125 unassigned setup is not BASIC/trial; empty catalog is explicit',
      (t) async {
    final f = PlansFixture()
      ..status = 'UNASSIGNED'
      ..cap = 50
      ..count = 0
      ..empty = true;
    late PlansController m;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts());
      await m.load();
    });
    await t.pumpWidget(app(m));
    await settle(t, m);
    expect(find.text('Unassigned'), findsOneWidget);
    expect(find.textContaining('Setup allows up to 50 active customers'),
        findsOneWidget);
    await reveal(t, find.textContaining('No active catalog plans'));
    expect(find.textContaining('No active catalog plans'), findsOneWidget);
    expect(find.text('BASIC'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
  testWidgets(
      'T-105 offline screen labels saved current and catalog separately',
      (t) async {
    final f = PlansFixture();
    late PlansController m;
    await t.runAsync(() async {
      m = model(f, MemoryDrafts());
      await m.load();
      f.offline = true;
    });
    await t.pumpWidget(app(m));
    await settle(t, m);
    expect(find.textContaining('Showing saved assignment'), findsOneWidget);
    await reveal(t, find.textContaining('Showing saved catalog'));
    expect(find.textContaining('Showing saved catalog'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    m.client.close();
  });
}
