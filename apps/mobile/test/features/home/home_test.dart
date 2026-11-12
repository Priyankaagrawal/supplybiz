import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/router/app_router.dart';
import 'package:supplybiz_mobile/core/router/guards.dart';
import 'package:supplybiz_mobile/core/router/routing_controller.dart';
import 'package:supplybiz_mobile/core/router/route_widgets.dart';
import 'package:supplybiz_mobile/features/auth/auth_pages.dart'
    show authEnabledProvider;
import 'package:supplybiz_mobile/core/storage/device_location.dart';
import 'package:supplybiz_mobile/features/home/home_controller.dart';
import 'package:supplybiz_mobile/features/home/home_page.dart';
import 'package:supplybiz_mobile/features/home/location_page.dart';
import 'package:supplybiz_mobile/features/home/search_page.dart';
import 'package:supplybiz_mobile/features/notifications/notifications_controller.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/addresses_test.dart' show reveal;
import 'home_fixture.dart';

const manualLocation = HomeLocation(
    address: 'Synthetic area',
    city: 'Synthetic city',
    pincode: '560001',
    latitude: 12.97,
    longitude: 77.59);
NetworkClient fixtureClient(HomeFixture fixture) => NetworkClient(
    baseUrl: 'https://api.example.test',
    session: TestSession(),
    adapter: fixture,
    delay: (_) async {});
HomeController homeModel(HomeFixture fixture, MemoryDrafts store,
    {String owner = 'synthetic:home'}) {
  final client = fixtureClient(fixture);
  addTearDown(client.close);
  return HomeController(client, store, owner);
}

HomeSearchController searchModel(HomeFixture fixture, MemoryDrafts store,
    {HomeLocation? location = manualLocation,
    String? category,
    String owner = 'synthetic:search'}) {
  final client = fixtureClient(fixture);
  addTearDown(client.close);
  return HomeSearchController(
      DiscoveryApi(client.dio), location, category, store, owner);
}

Widget homeApp(HomeController model, HomeFixture fixture,
    {Widget home = const CustomerHomePage(),
    double scale = 1,
    HomeSearchController? search}) {
  final client = fixtureClient(fixture);
  addTearDown(client.close);
  return ProviderScope(
      overrides: [
        homeProvider.overrideWith((ref) => model),
        notificationsProvider.overrideWith((ref) =>
            NotificationsController(NotificationsApi(client.dio), 'synthetic')),
        if (search != null)
          homeSearchProvider(null).overrideWith((ref) => search)
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
          home: home));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'search authorization denial clears memory even if encrypted cache cleanup fails',
      () async {
    final f = HomeFixture(),
        store = MemoryDrafts(),
        model = searchModel(f, store);
    addTearDown(model.dispose);
    await model.search('milk');
    store.fail = true;
    f.deny = true;
    await expectLater(model.search('milk'), completes);
    expect(model.items, isEmpty);
    expect(model.recent, isEmpty);
    expect(model.failure?.code, 'CACHE_CLEAR_FAILED');
  });
  testWidgets(
      'T-043 typed Home to location selection to category search uses live controller state',
      (tester) async {
    final f = HomeFixture(),
        store = MemoryDrafts(),
        m = homeModel(f, store),
        search = searchModel(f, store, category: homeCategoryId);
    await tester.runAsync(m.load);
    final client = fixtureClient(f);
    addTearDown(client.close);
    final routing = RoutingController()
      ..update(const RouteAccess(signedIn: true, activeRole: AppRole.customer));
    final router = createAppRouter(routing, initialLocation: '/customer/home');
    addTearDown(router.dispose);
    addTearDown(routing.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authEnabledProvider.overrideWithValue(true),
          homeProvider.overrideWith((ref) => m),
          homeSearchProvider(homeCategoryId).overrideWith((ref) => search),
          notificationsProvider.overrideWith((ref) => NotificationsController(
              NotificationsApi(client.dio), 'synthetic'))
        ],
        child: AppRoutingScope(
            controller: routing,
            environment: AppEnvironment.dev,
            child: MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  ...SbLocalizations.delegates
                ],
                supportedLocales: AppLocalizations.supportedLocales))));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SbButton,
        '${m.location!.address}, ${m.location!.city} · ${m.location!.pincode}'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomerLocationPage), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('home-address')), 'Another synthetic area');
    await reveal(tester, find.text('Use this location'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Use this location'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byType(CustomerHomePage), findsOneWidget);
    expect(m.location!.address, 'Another synthetic area');
    await reveal(tester, find.text('Milk and Dairy'));
    await tester.tap(find.text('Milk and Dairy'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomerSearchPage), findsOneWidget);
    expect(find.text('Synthetic search vendor'), findsOneWidget);
  });
  test(
      'TC-201 home defaults to owned saved address, paginates snapshots and refreshes persisted status',
      () async {
    final f = HomeFixture(), m = homeModel(f, MemoryDrafts());
    addTearDown(m.dispose);
    await m.load();
    expect(m.location?.pincode, '560001');
    expect(m.home!.deliveries.single.items.single.name, 'Synthetic milk');
    await m.more();
    expect(m.home!.deliveries, hasLength(2));
    f.status = 'PREPARING';
    await m.load();
    expect(m.home!.deliveries.single.status.value, 'PREPARING');
    expect(f.calls.where((r) => r.method != 'GET'), isEmpty);
  });
  test(
      'TC-200 selected location is account-scoped and restores without an automatic GPS request',
      () async {
    final f = HomeFixture()..addresses = [], store = MemoryDrafts();
    var m = homeModel(f, store);
    await m.load();
    expect(m.location, isNull);
    expect(await m.select(manualLocation), isTrue);
    m.dispose();
    m = homeModel(f, store);
    addTearDown(m.dispose);
    await m.load();
    expect(m.location?.address, manualLocation.address);
    final other = homeModel(f, store, owner: 'another-account:home');
    addTearDown(other.dispose);
    await other.load();
    expect(other.location, isNull);
    expect(
        await m.select(const HomeLocation(
            address: 'x',
            city: 'x',
            pincode: '000000',
            latitude: 0,
            longitude: 0)),
        isFalse);
  });
  test(
      'midnight invalid cursor reloads the first page; offline home is stale and role denial purges private state',
      () async {
    final f = HomeFixture(), store = MemoryDrafts(), m = homeModel(f, store);
    addTearDown(m.dispose);
    await m.load();
    f
      ..invalidCursor = true
      ..day = '2026-11-13';
    await m.more();
    expect(m.home!.businessDate.day, 13);
    expect(m.home!.deliveries, hasLength(1));
    f.offline = true;
    await m.load();
    expect(m.stale, isTrue);
    expect(m.home, isNotNull);
    f
      ..offline = false
      ..deny = true;
    await m.load();
    expect(m.failure, isA<ForbiddenFailure>());
    expect(m.home, isNull);
    expect(m.location, isNull);
    expect(await store.read(m.owner), isEmpty);
  });
  test(
      'TC-202 search sends validated location/category and stores bounded recent searches only within the account',
      () async {
    final f = HomeFixture(),
        store = MemoryDrafts(),
        m = searchModel(f, store, category: homeCategoryId);
    addTearDown(m.dispose);
    await m.search('milk');
    expect(m.items.single.businessName, 'Synthetic search vendor');
    expect(f.calls.last.queryParameters, containsPair('pincode', '560001'));
    expect(
        f.calls.last.queryParameters, containsPair('category', homeCategoryId));
    for (var i = 0; i < 12; i++) {
      await m.search('Synthetic $i');
    }
    expect(m.recent, hasLength(10));
    final restored = searchModel(f, store, category: homeCategoryId);
    addTearDown(restored.dispose);
    await restored.search('');
    expect(restored.recent, hasLength(10));
    final other = searchModel(f, store, owner: 'other:search');
    addTearDown(other.dispose);
    await other.search('');
    expect(other.recent, isEmpty);
    final noLocation = searchModel(f, store, location: null);
    addTearDown(noLocation.dispose);
    final count = f.calls.length;
    await noLocation.search('milk');
    expect(f.calls.length, count);
  });
  test(
      'TC-203 search handles empty/error/authorization states and ignores disposed responses',
      () async {
    final f = HomeFixture()..emptySearch = true,
        m = searchModel(f, MemoryDrafts());
    addTearDown(m.dispose);
    await m.search('none');
    expect(m.ready, isTrue);
    expect(m.items, isEmpty);
    f.offline = true;
    await m.search('milk');
    expect(m.failure, isA<NetworkFailure>());
    f
      ..offline = false
      ..deny = true;
    await m.search('milk');
    expect(m.items, isEmpty);
    expect(m.recent, isEmpty);
    final gate = Completer<void>(),
        late = HomeFixture()..gate = gate,
        disposed = searchModel(late, MemoryDrafts());
    final pending = disposed.search('milk');
    await late.started.future;
    disposed.dispose();
    gate.complete();
    await pending;
    expect(disposed.items, isEmpty);
  });
  test(
      'TC-200 manual coordinate/pincode boundaries reject missing, infinite and out-of-range input',
      () {
    for (final field in [
      'address',
      'city',
      'pincode',
      'latitude',
      'longitude'
    ]) {
      expect(validHomeLocationField(field, ''), isFalse);
    }
    for (final n in ['NaN', 'Infinity', '91', '-91']) {
      expect(validHomeLocationField('latitude', n), isFalse);
    }
    expect(validHomeLocationField('latitude', '-90'), isTrue);
    expect(validHomeLocationField('longitude', '180'), isTrue);
    expect(validHomeLocationField('pincode', '000000'), isFalse);
  });
  testWidgets(
      'TC-201 200% home renders snapshots/statuses and disables coming-soon categories',
      (tester) async {
    final f = HomeFixture(), m = homeModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    await tester.pumpWidget(homeApp(m, f, scale: 2));
    await tester.pumpAndSettle();
    final coming = find.widgetWithText(SbButton, 'Tiffin — Coming soon');
    expect(tester.widget<SbButton>(coming).onPressed, isNull);
    await reveal(tester, find.text('Accepted'));
    expect(find.text('Synthetic milk × 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'TC-200 denied GPS leaves manual 200% form available without mutating saved addresses',
      (tester) async {
    final f = HomeFixture()..addresses = [], m = homeModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceLocation.channel,
            (_) async => throw PlatformException(code: 'LOCATION_DENIED'));
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceLocation.channel, null));
    await tester
        .pumpWidget(homeApp(m, f, home: const HomeLocationForm(), scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Use current location'));
    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();
    expect(find.textContaining('manually'), findsWidgets);
    await reveal(tester, find.text('Use this location'));
    await tester.tap(find.text('Use this location'));
    await tester.pumpAndSettle();
    expect(f.calls.where((r) => r.method != 'GET'), isEmpty);
    expect(m.location, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('TC-203 200% search empty state suggests changing location',
      (tester) async {
    final f = HomeFixture()..emptySearch = true,
        m = homeModel(f, MemoryDrafts()),
        search = searchModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    await tester.pumpWidget(homeApp(m, f,
        home: const CustomerSearchPage(), search: search, scale: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('No vendors match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
