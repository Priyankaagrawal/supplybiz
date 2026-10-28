import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supplybiz_mobile/app.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/router/guards.dart';
import 'package:supplybiz_mobile/core/router/route_widgets.dart';
import 'package:supplybiz_mobile/core/router/routes.dart';
import 'package:supplybiz_mobile/core/router/routing_controller.dart';

const id = '11111111-1111-4111-8111-111111111111';
const customer = RouteAccess(
    languageSelected: true, signedIn: true, activeRole: AppRole.customer);
const vendor = RouteAccess(
    languageSelected: true,
    signedIn: true,
    activeRole: AppRole.vendor,
    onboardingComplete: true);

void main() {
  setUpAll(() async {
    for (final locale in ['en', 'hi']) {
      for (final delegate in SbLocalizations.delegates) {
        await delegate.load(Locale(locale));
      }
    }
  });

  Future<void> launch(WidgetTester tester, RoutingController controller) async {
    await tester.pumpWidget(SupplyBizApp(
        environment: AppEnvironment.dev, routingController: controller));
    await tester.pumpAndSettle();
  }

  BuildContext pageContext(WidgetTester tester) =>
      tester.element(find.byType(RoutePlaceholder).first);
  RouteTitle title(WidgetTester tester) => tester
      .widget<RoutePlaceholder>(find.byType(RoutePlaceholder).first)
      .title;
  Finder tab(String text) =>
      find.descendant(of: find.byType(SbBottomNav), matching: find.text(text));

  testWidgets(
      'T-013 deep link resumes after authentication to a typed detail route',
      (tester) async {
    final controller = RoutingController();
    addTearDown(controller.dispose);
    controller.openLink('supplybiz://o/$id');
    await launch(tester, controller);
    expect(title(tester), RouteTitle.language);
    controller.update(customer);
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.order);
    expect(
        GoRouter.of(pageContext(tester))
            .routeInformationProvider
            .value
            .uri
            .path,
        '/customer/orders/$id');
  });

  testWidgets(
      'T-013 five branches retain detail stacks and retapping resets the branch',
      (tester) async {
    final controller = RoutingController(access: customer);
    addTearDown(controller.dispose);
    await launch(tester, controller);
    expect(find.byType(NavigationDestination), findsNothing);
    expect(find.byType(SbBottomNav), findsOneWidget);
    const CustomerOrderRoute(id).go(pageContext(tester));
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.order);
    await tester.tap(tab('Home'));
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.home);
    await tester.tap(tab('Orders'));
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.order);
    await tester.tap(tab('Orders'));
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.orders);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.home);
  });

  testWidgets(
      'T-013 role mismatch prompts without switching; cancel returns to active Home',
      (tester) async {
    final controller = RoutingController(access: vendor);
    addTearDown(controller.dispose);
    await launch(tester, controller);
    controller.openLink('/v/$id');
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.switchRole);
    expect(controller.access.activeRole, AppRole.vendor);
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.home);
    expect(tab('Products'), findsOneWidget);
  });

  testWidgets(
      'T-013 invalid routes/IDs/enums and referral stub return Home safely',
      (tester) async {
    final controller = RoutingController(access: customer);
    addTearDown(controller.dispose);
    await launch(tester, controller);
    final router = GoRouter.of(pageContext(tester));
    for (final location in [
      '/not-a-route',
      '/unknown/$id',
      '/customer/orders/bad-id',
      '/common/invalid',
      '/vendor/onboarding/invalid',
      '/invite/FAKE'
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(find.byType(RoutePlaceholder), findsOneWidget, reason: location);
      expect(title(tester), RouteTitle.home, reason: location);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('T-013 all documented link kinds reach their typed placeholders',
      (tester) async {
    final controller = RoutingController(access: customer);
    addTearDown(controller.dispose);
    await launch(tester, controller);
    final router = GoRouter.of(pageContext(tester));
    for (final access in [customer, vendor]) {
      controller.update(access);
      await tester.pumpAndSettle();
      for (final kind in [
        'o',
        's',
        if (access.activeRole == AppRole.customer) ...['v', 'khata']
      ]) {
        router.go('/$kind/$id');
        await tester.pumpAndSettle();
        expect(
            title(tester),
            switch (kind) {
              'o' => RouteTitle.order,
              's' => RouteTitle.subscription,
              'v' => RouteTitle.vendor,
              _ => RouteTitle.ledger,
            });
        expect(tester.takeException(), isNull);
      }
    }
    controller.update(customer);
    await tester.pumpAndSettle();
    router.go('supplybiz://o/$id');
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.order);
  });

  testWidgets('T-013 shell is localized at 200% and exposes labelled 48dp tabs',
      (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('hi')];
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = RoutingController(access: customer);
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();
    await launch(tester, controller);
    expect(tab('सेवाएँ'), findsOneWidget);
    await tester.tap(tab('सेवाएँ'));
    await tester.pumpAndSettle();
    expect(title(tester), RouteTitle.services);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
