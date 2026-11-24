// T-122 / TC-270: simulated HTTP; live API/DB/device acceptance stays separate.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart'
    hide DiscoveryPage;
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/router/app_router.dart';
import 'package:supplybiz_mobile/core/router/guards.dart';
import 'package:supplybiz_mobile/core/router/route_widgets.dart';
import 'package:supplybiz_mobile/core/router/routing_controller.dart';
import 'package:supplybiz_mobile/features/auth/auth_pages.dart'
    show authEnabledProvider;
import 'package:supplybiz_mobile/features/discovery/cart_controller.dart';
import 'package:supplybiz_mobile/features/discovery/discovery_controller.dart';
import 'package:supplybiz_mobile/features/discovery/discovery_page.dart';
import 'package:supplybiz_mobile/features/discovery/favorites_controller.dart';
import 'package:supplybiz_mobile/features/home/home_controller.dart';
import 'package:supplybiz_mobile/features/services/services_page.dart';
import 'package:ui_kit/ui_kit.dart';
import '../discovery/discovery_fixture.dart';
import '../home/home_fixture.dart';
import '../home/home_test.dart' show homeApp, homeModel, manualLocation;
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Finder category(String label) => find.widgetWithText(SbButton, label);
  SbButton button(WidgetTester tester, String label) =>
      tester.widget<SbButton>(category(label));

  testWidgets('TC-270 Services route opens the category-filtered vendor list',
      (tester) async {
    final fixture = HomeFixture(), store = MemoryDrafts();
    final model = homeModel(fixture, store);
    await tester.runAsync(model.load);
    final discovery = DiscoveryFixture();
    final client = NetworkClient(
        baseUrl: 'https://api.example.test',
        session: TestSession(),
        adapter: discovery,
        delay: (_) async {});
    addTearDown(client.close);
    final api = DiscoveryApi(client.dio);
    final list = DiscoveryController(
        api, manualLocation, (category: homeCategoryId, favorites: false));
    final routing = RoutingController(
        access:
            const RouteAccess(signedIn: true, activeRole: AppRole.customer));
    final router =
        createAppRouter(routing, initialLocation: '/customer/services');
    addTearDown(router.dispose);
    addTearDown(routing.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authEnabledProvider.overrideWithValue(true),
          homeProvider.overrideWith((ref) => model),
          discoveryProvider((category: homeCategoryId, favorites: false))
              .overrideWith((ref) => list),
          favoritesProvider.overrideWith((ref) => FavoritesController(
              api, store, 'synthetic:favorites', manualLocation)),
          cartProvider
              .overrideWith((ref) => CartController(store, 'synthetic:cart')),
        ],
        child: AppRoutingScope(
            controller: routing,
            environment: AppEnvironment.dev,
            child: MaterialApp.router(
                routerConfig: router,
                theme: sbLightTheme(const Locale('en')),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  ...SbLocalizations.delegates
                ],
                supportedLocales: AppLocalizations.supportedLocales))));
    await tester.pumpAndSettle();
    expect(find.byType(ServicesPage), findsOneWidget);
    expect(button(tester, 'Tiffin — Coming soon').onPressed, isNull);
    await tester.tap(category('Milk and Dairy'));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoveryPage), findsOneWidget);
    expect(find.text('Synthetic discovery vendor'), findsOneWidget);
    final call =
        discovery.calls.firstWhere((c) => c.uri.path.endsWith('/vendors'));
    expect(call.queryParameters['category'], homeCategoryId);
    expect(call.queryParameters['pincode'], manualLocation.pincode);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ServicesPage), findsOneWidget);
    expect(find.byType(SbBottomNav), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-270 unsupported categories cannot navigate or start payments',
      (tester) async {
    final f = HomeFixture(), m = homeModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    // Both status and availability must permit discovery.
    final json = homeJson();
    (json['categories'] as List)[1]['available'] = true;
    m.home = CustomerHome.fromJson(json);
    await tester.pumpWidget(homeApp(m, f, home: const ServicesPage()));
    await tester.pumpAndSettle();
    expect(button(tester, 'Tiffin — Coming soon').onPressed, isNull);
    expect(button(tester, 'Milk and Dairy').onPressed, isNotNull);
    expect(find.textContaining('bill', findRichText: true), findsNothing);
    expect(find.textContaining('Recharge'), findsNothing);
    expect(find.textContaining('recognition'), findsNothing);
  });

  testWidgets(
      'loading disables opening categories and refresh without empty flash',
      (tester) async {
    final f = HomeFixture(), m = homeModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    m.busy = true;
    await tester.pumpWidget(homeApp(m, f, home: const ServicesPage()));
    await tester.pump();
    expect(find.byType(SbSkeleton), findsOneWidget);
    expect(button(tester, 'Milk and Dairy').onPressed, isNull);
    expect(button(tester, 'Refresh services').onPressed, isNull);
    expect(find.byType(SbEmpty), findsNothing);
  });

  testWidgets('empty directory has a refresh action and no invented categories',
      (tester) async {
    final f = HomeFixture(), m = homeModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    m.home = CustomerHome.fromJson(homeJson()..['categories'] = []);
    await tester.pumpWidget(homeApp(m, f, home: const ServicesPage()));
    await tester.pumpAndSettle();
    expect(
        find.text('No supply categories are available yet.'), findsOneWidget);
    expect(button(tester, 'Refresh services').onPressed, isNotNull);
    expect(category('Milk and Dairy'), findsNothing);
  });

  testWidgets(
      'offline first load exposes safe error and successful explicit retry',
      (tester) async {
    final f = HomeFixture()..offline = true;
    final m = homeModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    await tester.pumpWidget(homeApp(m, f, home: const ServicesPage()));
    await tester.pumpAndSettle();
    expect(m.failure, isA<NetworkFailure>());
    expect(find.byType(SbEmpty), findsNothing);
    expect(category('Milk and Dairy'), findsNothing);
    f.offline = false;
    await tester.runAsync(() async {
      await tester.tap(category('Refresh services'));
      for (var i = 0; i < 100 && m.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(m.failure, isNull);
    expect(button(tester, 'Milk and Dairy').onPressed, isNotNull);
  });

  testWidgets(
      'offline refresh keeps last labels but locks routing until refreshed',
      (tester) async {
    final f = HomeFixture(), m = homeModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    f.offline = true;
    await tester.runAsync(m.load);
    await tester.pumpWidget(homeApp(m, f, home: const ServicesPage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Showing the last loaded services.'),
        findsOneWidget);
    expect(button(tester, 'Milk and Dairy').onPressed, isNull);
    f.offline = false;
    await tester.runAsync(() async {
      await tester.tap(category('Refresh services'));
      for (var i = 0; i < 100 && m.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(button(tester, 'Milk and Dairy').onPressed, isNotNull);
    expect(
        find.textContaining('Showing the last loaded services.'), findsNothing);
  });

  testWidgets('authorization denial clears the previously loaded directory',
      (tester) async {
    final f = HomeFixture(), m = homeModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    f.deny = true;
    await tester.runAsync(m.load);
    await tester.pumpWidget(homeApp(m, f, home: const ServicesPage()));
    await tester.pumpAndSettle();
    expect(m.home, isNull);
    expect(category('Milk and Dairy'), findsNothing);
    expect(m.failure, isA<ForbiddenFailure>());
  });

  testWidgets(
      '200 percent text and long names remain scrollable with 48dp targets',
      (tester) async {
    final f = HomeFixture(), m = homeModel(f, MemoryDrafts());
    await tester.runAsync(m.load);
    final json = homeJson();
    final name = List.filled(8, 'Synthetic supply category').join(' ');
    (json['categories'] as List)[0]['name'] = name;
    m.home = CustomerHome.fromJson(json);
    await tester
        .pumpWidget(homeApp(m, f, home: const ServicesPage(), scale: 2));
    await tester.pumpAndSettle();
    await tester.ensureVisible(category(name));
    expect(tester.getSize(category(name)).height, greaterThanOrEqualTo(48));
    await tester.scrollUntilVisible(category('Tiffin — Coming soon'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(tester.getSize(category('Tiffin — Coming soon')).height,
        greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}
