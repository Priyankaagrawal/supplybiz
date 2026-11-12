import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_widgets.dart';
import 'guards.dart';
import '../../features/auth/auth_pages.dart';
import '../../features/onboarding/onboarding_pages.dart';
import '../../features/service_area/service_area_page.dart';
import '../../features/products/products_page.dart';
import '../../features/customers/customers_page.dart';
import '../../features/customers/customer_editor.dart';
import '../../features/addresses/addresses_page.dart';
import '../../features/addresses/address_editor.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/home/home_page.dart';
import '../../features/home/location_page.dart';
import '../../features/home/search_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/discovery/discovery_page.dart';
import '../../features/discovery/vendor_page.dart';
import '../../features/discovery/product_page.dart';

part 'routes.g.dart';

@TypedGoRoute<CustomerDiscoveryRoute>(path: '/customer/vendors')
class CustomerDiscoveryRoute extends GoRouteData with _$CustomerDiscoveryRoute {
  const CustomerDiscoveryRoute({this.category});
  final String? category;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DiscoveryPage(category: category);
}

@TypedGoRoute<CustomerFavoritesRoute>(path: '/customer/favorites')
class CustomerFavoritesRoute extends GoRouteData with _$CustomerFavoritesRoute {
  const CustomerFavoritesRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DiscoveryPage(favorites: true);
}

class CustomerProductRoute extends GoRouteData with _$CustomerProductRoute {
  const CustomerProductRoute(this.id, this.productId);
  final String id, productId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomerProductPage(id: id, productId: productId);
}

@TypedGoRoute<CustomerLocationRoute>(path: '/customer/location')
class CustomerLocationRoute extends GoRouteData with _$CustomerLocationRoute {
  const CustomerLocationRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CustomerLocationPage();
}

@TypedGoRoute<CustomerSearchRoute>(path: '/customer/search')
class CustomerSearchRoute extends GoRouteData with _$CustomerSearchRoute {
  const CustomerSearchRoute({this.category});
  final String? category;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomerSearchPage(category: category);
}

@TypedGoRoute<CustomerAddressesRoute>(path: '/customer/addresses', routes: [
  TypedGoRoute<CustomerAddressNewRoute>(path: 'new'),
  TypedGoRoute<CustomerAddressEditRoute>(path: ':id/edit'),
])
class CustomerAddressesRoute extends GoRouteData with _$CustomerAddressesRoute {
  const CustomerAddressesRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AddressesPage();
}

class CustomerAddressNewRoute extends GoRouteData
    with _$CustomerAddressNewRoute {
  const CustomerAddressNewRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AddressEditorPage();
}

class CustomerAddressEditRoute extends GoRouteData
    with _$CustomerAddressEditRoute {
  const CustomerAddressEditRoute(this.id);
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AddressEditorPage(id: id);
}

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with _$SplashRoute {
  const SplashRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AuthPage(RouteTitle.loading);
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with _$LoginRoute {
  const LoginRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AuthPage(RouteTitle.login);
}

@TypedGoRoute<OtpRoute>(path: '/otp')
class OtpRoute extends GoRouteData with _$OtpRoute {
  const OtpRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AuthPage(RouteTitle.otp);
}

@TypedGoRoute<RoleRoute>(path: '/role')
class RoleRoute extends GoRouteData with _$RoleRoute {
  const RoleRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AuthPage(RouteTitle.role);
}

@TypedGoRoute<CommonRoute>(path: '/common/:page')
class CommonRoute extends GoRouteData with _$CommonRoute {
  const CommonRoute(this.page);
  final CommonPage page;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      page == CommonPage.notifications
          ? const NotificationsPage()
          : page == CommonPage.settings || page == CommonPage.switchRole
              ? AuthPage(page == CommonPage.settings
                  ? RouteTitle.settings
                  : RouteTitle.switchRole)
              : RoutePlaceholder(
                  title: switch (page) {
                  CommonPage.update => RouteTitle.update,
                  CommonPage.legal => RouteTitle.legal,
                  CommonPage.notifications => RouteTitle.notifications,
                  CommonPage.settings => RouteTitle.settings,
                  CommonPage.switchRole => RouteTitle.switchRole,
                });
}

enum CommonPage { update, legal, notifications, settings, switchRole }

@TypedGoRoute<OnboardingRoute>(path: '/vendor/onboarding/:step')
class OnboardingRoute extends GoRouteData with _$OnboardingRoute {
  const OnboardingRoute(this.step);
  final OnboardingStep step;
  @override
  Widget build(BuildContext context, GoRouterState state) => Consumer(
      builder: (context, ref, _) => ref.watch(authEnabledProvider)
          ? const OnboardingPage()
          : const RoutePlaceholder(title: RouteTitle.onboarding));
}

@TypedStatefulShellRoute<VendorShell>(branches: [
  TypedStatefulShellBranch<VendorHomeBranch>(
      routes: [TypedGoRoute<VendorHomeRoute>(path: '/vendor/home')]),
  TypedStatefulShellBranch<VendorOrdersBranch>(routes: [
    TypedGoRoute<VendorOrdersRoute>(
        path: '/vendor/orders',
        routes: [TypedGoRoute<VendorOrderRoute>(path: ':id')])
  ]),
  TypedStatefulShellBranch<VendorProductsBranch>(
      routes: [TypedGoRoute<VendorProductsRoute>(path: '/vendor/products')]),
  TypedStatefulShellBranch<VendorCustomersBranch>(routes: [
    TypedGoRoute<VendorCustomersRoute>(path: '/vendor/customers', routes: [
      TypedGoRoute<VendorCustomerNewRoute>(path: 'new'),
      TypedGoRoute<VendorCustomerRoute>(
          path: ':id',
          routes: [TypedGoRoute<VendorCustomerEditRoute>(path: 'edit')]),
      TypedGoRoute<VendorSubscriptionRoute>(path: 'subscriptions/:id')
    ])
  ]),
  TypedStatefulShellBranch<VendorMoreBranch>(
      routes: [TypedGoRoute<VendorMoreRoute>(path: '/vendor/more')]),
])
class VendorShell extends StatefulShellRouteData {
  const VendorShell();
  @override
  Widget builder(BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) =>
      RoleShell(shell: navigationShell, role: AppRole.vendor);
}

class VendorHomeBranch extends StatefulShellBranchData {
  const VendorHomeBranch();
}

class VendorHomeRoute extends GoRouteData with _$VendorHomeRoute {
  const VendorHomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.home);
}

class VendorOrdersBranch extends StatefulShellBranchData {
  const VendorOrdersBranch();
}

class VendorOrdersRoute extends GoRouteData with _$VendorOrdersRoute {
  const VendorOrdersRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.orders);
}

class VendorOrderRoute extends GoRouteData with _$VendorOrderRoute {
  const VendorOrderRoute(this.id);
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.order);
}

class VendorProductsBranch extends StatefulShellBranchData {
  const VendorProductsBranch();
}

class VendorProductsRoute extends GoRouteData with _$VendorProductsRoute {
  const VendorProductsRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProductsPage();
}

class VendorCustomersBranch extends StatefulShellBranchData {
  const VendorCustomersBranch();
}

class VendorCustomersRoute extends GoRouteData with _$VendorCustomersRoute {
  const VendorCustomersRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => Consumer(
      builder: (context, ref, _) => ref.watch(authEnabledProvider)
          ? const CustomersPage()
          : const RoutePlaceholder(title: RouteTitle.customers));
}

class VendorCustomerNewRoute extends GoRouteData with _$VendorCustomerNewRoute {
  const VendorCustomerNewRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CustomerEditorPage();
}

class VendorCustomerRoute extends GoRouteData with _$VendorCustomerRoute {
  const VendorCustomerRoute(this.id);
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomerDetailPage(id: id);
}

class VendorCustomerEditRoute extends GoRouteData
    with _$VendorCustomerEditRoute {
  const VendorCustomerEditRoute(this.id);
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CustomerEditorPage(id: id);
}

class VendorSubscriptionRoute extends GoRouteData
    with _$VendorSubscriptionRoute {
  const VendorSubscriptionRoute(this.id);
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.subscription);
}

class VendorMoreBranch extends StatefulShellBranchData {
  const VendorMoreBranch();
}

class VendorMoreRoute extends GoRouteData with _$VendorMoreRoute {
  const VendorMoreRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.more);
}

@TypedGoRoute<ServiceAreaRoute>(path: '/vendor/service-area')
class ServiceAreaRoute extends GoRouteData with _$ServiceAreaRoute {
  const ServiceAreaRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ServiceAreaPage();
}

@TypedStatefulShellRoute<CustomerShell>(branches: [
  TypedStatefulShellBranch<CustomerHomeBranch>(routes: [
    TypedGoRoute<CustomerHomeRoute>(path: '/customer/home', routes: [
      TypedGoRoute<CustomerVendorRoute>(path: 'vendors/:id', routes: [
        TypedGoRoute<CustomerProductRoute>(path: 'products/:productId')
      ])
    ])
  ]),
  TypedStatefulShellBranch<CustomerOrdersBranch>(routes: [
    TypedGoRoute<CustomerOrdersRoute>(path: '/customer/orders', routes: [
      TypedGoRoute<CustomerOrderRoute>(path: ':id'),
      TypedGoRoute<CustomerSubscriptionRoute>(path: 'subscriptions/:id')
    ])
  ]),
  TypedStatefulShellBranch<CustomerKhataBranch>(routes: [
    TypedGoRoute<CustomerKhataRoute>(
        path: '/customer/khata',
        routes: [TypedGoRoute<CustomerLedgerRoute>(path: ':id')])
  ]),
  TypedStatefulShellBranch<CustomerServicesBranch>(routes: [
    TypedGoRoute<CustomerServicesRoute>(path: '/customer/services')
  ]),
  TypedStatefulShellBranch<CustomerProfileBranch>(
      routes: [TypedGoRoute<CustomerProfileRoute>(path: '/customer/profile')]),
])
class CustomerShell extends StatefulShellRouteData {
  const CustomerShell();
  @override
  Widget builder(BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) =>
      RoleShell(shell: navigationShell, role: AppRole.customer);
}

class CustomerHomeBranch extends StatefulShellBranchData {
  const CustomerHomeBranch();
}

class CustomerHomeRoute extends GoRouteData with _$CustomerHomeRoute {
  const CustomerHomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => Consumer(
      builder: (context, ref, _) => ref.watch(authEnabledProvider)
          ? const CustomerHomePage()
          : const RoutePlaceholder(title: RouteTitle.home));
}

class CustomerVendorRoute extends GoRouteData with _$CustomerVendorRoute {
  const CustomerVendorRoute(this.id);
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) => Consumer(
      builder: (context, ref, _) => ref.watch(authEnabledProvider)
          ? CustomerVendorPage(id: id)
          : const RoutePlaceholder(title: RouteTitle.vendor));
}

class CustomerOrdersBranch extends StatefulShellBranchData {
  const CustomerOrdersBranch();
}

class CustomerOrdersRoute extends GoRouteData with _$CustomerOrdersRoute {
  const CustomerOrdersRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.orders);
}

class CustomerOrderRoute extends GoRouteData with _$CustomerOrderRoute {
  const CustomerOrderRoute(this.id);
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.order);
}

class CustomerSubscriptionRoute extends GoRouteData
    with _$CustomerSubscriptionRoute {
  const CustomerSubscriptionRoute(this.id);
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.subscription);
}

class CustomerKhataBranch extends StatefulShellBranchData {
  const CustomerKhataBranch();
}

class CustomerKhataRoute extends GoRouteData with _$CustomerKhataRoute {
  const CustomerKhataRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.khata);
}

class CustomerLedgerRoute extends GoRouteData with _$CustomerLedgerRoute {
  const CustomerLedgerRoute(this.id);
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.ledger);
}

class CustomerServicesBranch extends StatefulShellBranchData {
  const CustomerServicesBranch();
}

class CustomerServicesRoute extends GoRouteData with _$CustomerServicesRoute {
  const CustomerServicesRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.services);
}

class CustomerProfileBranch extends StatefulShellBranchData {
  const CustomerProfileBranch();
}

class CustomerProfileRoute extends GoRouteData with _$CustomerProfileRoute {
  const CustomerProfileRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.profile);
}

@TypedGoRoute<LinkRoute>(path: '/:kind/:id')
class LinkRoute extends GoRouteData with _$LinkRoute {
  const LinkRoute(this.kind, this.id);
  final String kind;
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RoutePlaceholder(title: RouteTitle.loading);
}
