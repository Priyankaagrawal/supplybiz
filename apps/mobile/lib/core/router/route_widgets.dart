import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../config/app_environment.dart';
import '../l10n/l10n.dart';
import 'guards.dart';
import 'routing_controller.dart';
import 'routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_pages.dart';
import '../../features/onboarding/onboarding_controller.dart';
import '../../features/onboarding/onboarding_pages.dart';

class AppRoutingScope extends InheritedWidget {
  const AppRoutingScope(
      {required this.controller,
      required this.environment,
      required super.child,
      super.key});
  final RoutingController controller;
  final AppEnvironment environment;
  static AppRoutingScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppRoutingScope>()!;
  @override
  bool updateShouldNotify(AppRoutingScope oldWidget) =>
      oldWidget.controller != controller ||
      oldWidget.environment != environment;
}

enum RouteTitle {
  loading,
  login,
  otp,
  role,
  onboarding,
  update,
  legal,
  notifications,
  settings,
  switchRole,
  home,
  orders,
  products,
  customers,
  more,
  khata,
  services,
  profile,
  order,
  subscription,
  vendor,
  ledger,
}

String routeLabel(BuildContext context, RouteTitle title) {
  final l10n = context.l10n;
  return switch (title) {
    RouteTitle.loading => l10n.routeLoading,
    RouteTitle.login => l10n.routeLogin,
    RouteTitle.otp => l10n.routeOtp,
    RouteTitle.role => l10n.routeRole,
    RouteTitle.onboarding => l10n.routeOnboarding,
    RouteTitle.update => l10n.routeUpdate,
    RouteTitle.legal => l10n.routeLegal,
    RouteTitle.notifications => l10n.routeNotifications,
    RouteTitle.settings => l10n.routeSettings,
    RouteTitle.switchRole => l10n.routeSwitchRole,
    RouteTitle.home => l10n.navHome,
    RouteTitle.orders => l10n.navOrders,
    RouteTitle.products => l10n.navProducts,
    RouteTitle.customers => l10n.navCustomers,
    RouteTitle.more => l10n.navMore,
    RouteTitle.khata => l10n.navKhata,
    RouteTitle.services => l10n.navServices,
    RouteTitle.profile => l10n.navProfile,
    RouteTitle.order => l10n.routeOrder,
    RouteTitle.subscription => l10n.routeSubscription,
    RouteTitle.vendor => l10n.routeVendor,
    RouteTitle.ledger => l10n.routeLedger,
  };
}

/// S-COM-01–06 / S-V-01–04 and role destinations are placeholders until their
/// owning tasks. They cannot create a session, change a role or grant access.
class RoutePlaceholder extends StatelessWidget {
  const RoutePlaceholder({required this.title, super.key});
  final RouteTitle title;

  @override
  Widget build(BuildContext context) {
    final scope = AppRoutingScope.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName), actions: [
        if (scope.controller.access.signedIn)
          SbIconButton(
              icon: Icons.notifications_outlined,
              semanticLabel: l10n.routeNotifications,
              onPressed: () => const CommonRoute(CommonPage.notifications)
                  .push<void>(context)),
        Consumer(
            builder: (context, ref, _) => ref.watch(authEnabledProvider) &&
                    scope.controller.access.signedIn
                ? SbIconButton(
                    icon: Icons.manage_accounts_outlined,
                    semanticLabel: l10n.routeSettings,
                    onPressed: () =>
                        const CommonRoute(CommonPage.settings).go(context))
                : const SizedBox.shrink())
      ]),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Semantics(
              header: true,
              child: Text(routeLabel(context, title),
                  style: Theme.of(context).textTheme.headlineSmall)),
          if (title == RouteTitle.home &&
              scope.controller.access.activeRole == AppRole.vendor)
            Consumer(builder: (context, ref, _) {
              if (!ref.watch(authEnabledProvider)) {
                return const SizedBox.shrink();
              }
              final model = ref.watch(onboardingProvider);
              return Column(children: [
                VerificationStatus(model: model),
                TextButton(
                    onPressed: () =>
                        const OnboardingRoute(OnboardingStep.status)
                            .go(context),
                    child: Text(l10n.onboardingRefresh))
              ]);
            }),
          const SizedBox(height: 16),
          if (title == RouteTitle.more)
            SbButton(
                label: l10n.areaTitle,
                onPressed: () => const ServiceAreaRoute().push<void>(context)),
          if (title == RouteTitle.profile)
            Consumer(
                builder: (context, ref, _) => ref.watch(authEnabledProvider)
                    ? SbButton(
                        label: l10n.addressTitle,
                        onPressed: () =>
                            const CustomerAddressesRoute().push<void>(context))
                    : const SizedBox.shrink()),
          Text(
              title == RouteTitle.switchRole
                  ? l10n.routeSwitchMessage
                  : l10n.routePlaceholder,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(switch (scope.environment) {
            AppEnvironment.dev => l10n.developmentEnvironment,
            AppEnvironment.staging => l10n.stagingEnvironment,
            AppEnvironment.prod => l10n.productionEnvironment,
          }),
          if (title == RouteTitle.switchRole)
            ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: TextButton(
                    onPressed: scope.controller.cancelPending,
                    child: Text(l10n.routeHomeAction))),
        ])),
      )),
    );
  }
}

/// S-V-05/S-V-19 and S-C-01/S-C-27 shells. Tab content belongs to later tasks.
class RoleShell extends StatelessWidget {
  const RoleShell({required this.shell, required this.role, super.key});
  final StatefulNavigationShell shell;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final tabs = role == AppRole.vendor
        ? [
            RouteTitle.home,
            RouteTitle.orders,
            RouteTitle.products,
            RouteTitle.customers,
            RouteTitle.more
          ]
        : [
            RouteTitle.home,
            RouteTitle.orders,
            RouteTitle.khata,
            RouteTitle.services,
            RouteTitle.profile
          ];
    final icons = role == AppRole.vendor
        ? [
            Icons.home_outlined,
            Icons.receipt_long_outlined,
            Icons.inventory_2_outlined,
            Icons.people_outline,
            Icons.more_horiz
          ]
        : [
            Icons.home_outlined,
            Icons.receipt_long_outlined,
            Icons.account_balance_wallet_outlined,
            Icons.grid_view,
            Icons.person_outline
          ];
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (shell.currentIndex != 0 && !GoRouter.of(context).canPop()) {
          shell.goBranch(0, initialLocation: true);
          return true;
        }
        return false;
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: SbBottomNav(
          selectedIndex: shell.currentIndex,
          onSelected: (index) => shell.goBranch(index,
              initialLocation: index == shell.currentIndex),
          items: [
            for (var i = 0; i < tabs.length; i++)
              NavigationDestination(
                  icon: Icon(icons[i]), label: routeLabel(context, tabs[i]))
          ],
        ),
      ),
    );
  }
}
