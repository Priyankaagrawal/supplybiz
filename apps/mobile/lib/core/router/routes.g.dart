// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
      $splashRoute,
      $languageRoute,
      $loginRoute,
      $otpRoute,
      $roleRoute,
      $commonRoute,
      $onboardingRoute,
      $vendorShell,
      $customerShell,
      $linkRoute,
    ];

RouteBase get $splashRoute => GoRouteData.$route(
      path: '/splash',
      factory: _$SplashRoute._fromState,
    );

mixin _$SplashRoute on GoRouteData {
  static SplashRoute _fromState(GoRouterState state) => const SplashRoute();

  @override
  String get location => GoRouteData.$location(
        '/splash',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $languageRoute => GoRouteData.$route(
      path: '/language',
      factory: _$LanguageRoute._fromState,
    );

mixin _$LanguageRoute on GoRouteData {
  static LanguageRoute _fromState(GoRouterState state) => const LanguageRoute();

  @override
  String get location => GoRouteData.$location(
        '/language',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute => GoRouteData.$route(
      path: '/login',
      factory: _$LoginRoute._fromState,
    );

mixin _$LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location(
        '/login',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $otpRoute => GoRouteData.$route(
      path: '/otp',
      factory: _$OtpRoute._fromState,
    );

mixin _$OtpRoute on GoRouteData {
  static OtpRoute _fromState(GoRouterState state) => const OtpRoute();

  @override
  String get location => GoRouteData.$location(
        '/otp',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $roleRoute => GoRouteData.$route(
      path: '/role',
      factory: _$RoleRoute._fromState,
    );

mixin _$RoleRoute on GoRouteData {
  static RoleRoute _fromState(GoRouterState state) => const RoleRoute();

  @override
  String get location => GoRouteData.$location(
        '/role',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $commonRoute => GoRouteData.$route(
      path: '/common/:page',
      factory: _$CommonRoute._fromState,
    );

mixin _$CommonRoute on GoRouteData {
  static CommonRoute _fromState(GoRouterState state) => CommonRoute(
        _$CommonPageEnumMap._$fromName(state.pathParameters['page']!)!,
      );

  CommonRoute get _self => this as CommonRoute;

  @override
  String get location => GoRouteData.$location(
        '/common/${Uri.encodeComponent(_$CommonPageEnumMap[_self.page]!)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

const _$CommonPageEnumMap = {
  CommonPage.update: 'update',
  CommonPage.legal: 'legal',
  CommonPage.notifications: 'notifications',
  CommonPage.settings: 'settings',
  CommonPage.switchRole: 'switch-role',
};

extension<T extends Enum> on Map<T, String> {
  T? _$fromName(String? value) =>
      entries.where((element) => element.value == value).firstOrNull?.key;
}

RouteBase get $onboardingRoute => GoRouteData.$route(
      path: '/vendor/onboarding/:step',
      factory: _$OnboardingRoute._fromState,
    );

mixin _$OnboardingRoute on GoRouteData {
  static OnboardingRoute _fromState(GoRouterState state) => OnboardingRoute(
        _$OnboardingStepEnumMap._$fromName(state.pathParameters['step']!)!,
      );

  OnboardingRoute get _self => this as OnboardingRoute;

  @override
  String get location => GoRouteData.$location(
        '/vendor/onboarding/${Uri.encodeComponent(_$OnboardingStepEnumMap[_self.step]!)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

const _$OnboardingStepEnumMap = {
  OnboardingStep.category: 'category',
  OnboardingStep.business: 'business',
  OnboardingStep.kyc: 'kyc',
  OnboardingStep.status: 'status',
};

RouteBase get $vendorShell => StatefulShellRouteData.$route(
      factory: $VendorShellExtension._fromState,
      branches: [
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/vendor/home',
              factory: _$VendorHomeRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/vendor/orders',
              factory: _$VendorOrdersRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: ':id',
                  factory: _$VendorOrderRoute._fromState,
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/vendor/products',
              factory: _$VendorProductsRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/vendor/customers',
              factory: _$VendorCustomersRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'subscriptions/:id',
                  factory: _$VendorSubscriptionRoute._fromState,
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/vendor/more',
              factory: _$VendorMoreRoute._fromState,
            ),
          ],
        ),
      ],
    );

extension $VendorShellExtension on VendorShell {
  static VendorShell _fromState(GoRouterState state) => const VendorShell();
}

mixin _$VendorHomeRoute on GoRouteData {
  static VendorHomeRoute _fromState(GoRouterState state) =>
      const VendorHomeRoute();

  @override
  String get location => GoRouteData.$location(
        '/vendor/home',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$VendorOrdersRoute on GoRouteData {
  static VendorOrdersRoute _fromState(GoRouterState state) =>
      const VendorOrdersRoute();

  @override
  String get location => GoRouteData.$location(
        '/vendor/orders',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$VendorOrderRoute on GoRouteData {
  static VendorOrderRoute _fromState(GoRouterState state) => VendorOrderRoute(
        state.pathParameters['id']!,
      );

  VendorOrderRoute get _self => this as VendorOrderRoute;

  @override
  String get location => GoRouteData.$location(
        '/vendor/orders/${Uri.encodeComponent(_self.id)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$VendorProductsRoute on GoRouteData {
  static VendorProductsRoute _fromState(GoRouterState state) =>
      const VendorProductsRoute();

  @override
  String get location => GoRouteData.$location(
        '/vendor/products',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$VendorCustomersRoute on GoRouteData {
  static VendorCustomersRoute _fromState(GoRouterState state) =>
      const VendorCustomersRoute();

  @override
  String get location => GoRouteData.$location(
        '/vendor/customers',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$VendorSubscriptionRoute on GoRouteData {
  static VendorSubscriptionRoute _fromState(GoRouterState state) =>
      VendorSubscriptionRoute(
        state.pathParameters['id']!,
      );

  VendorSubscriptionRoute get _self => this as VendorSubscriptionRoute;

  @override
  String get location => GoRouteData.$location(
        '/vendor/customers/subscriptions/${Uri.encodeComponent(_self.id)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$VendorMoreRoute on GoRouteData {
  static VendorMoreRoute _fromState(GoRouterState state) =>
      const VendorMoreRoute();

  @override
  String get location => GoRouteData.$location(
        '/vendor/more',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $customerShell => StatefulShellRouteData.$route(
      factory: $CustomerShellExtension._fromState,
      branches: [
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/customer/home',
              factory: _$CustomerHomeRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'vendors/:id',
                  factory: _$CustomerVendorRoute._fromState,
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/customer/orders',
              factory: _$CustomerOrdersRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: ':id',
                  factory: _$CustomerOrderRoute._fromState,
                ),
                GoRouteData.$route(
                  path: 'subscriptions/:id',
                  factory: _$CustomerSubscriptionRoute._fromState,
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/customer/khata',
              factory: _$CustomerKhataRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: ':id',
                  factory: _$CustomerLedgerRoute._fromState,
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/customer/services',
              factory: _$CustomerServicesRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/customer/profile',
              factory: _$CustomerProfileRoute._fromState,
            ),
          ],
        ),
      ],
    );

extension $CustomerShellExtension on CustomerShell {
  static CustomerShell _fromState(GoRouterState state) => const CustomerShell();
}

mixin _$CustomerHomeRoute on GoRouteData {
  static CustomerHomeRoute _fromState(GoRouterState state) =>
      const CustomerHomeRoute();

  @override
  String get location => GoRouteData.$location(
        '/customer/home',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$CustomerVendorRoute on GoRouteData {
  static CustomerVendorRoute _fromState(GoRouterState state) =>
      CustomerVendorRoute(
        state.pathParameters['id']!,
      );

  CustomerVendorRoute get _self => this as CustomerVendorRoute;

  @override
  String get location => GoRouteData.$location(
        '/customer/home/vendors/${Uri.encodeComponent(_self.id)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$CustomerOrdersRoute on GoRouteData {
  static CustomerOrdersRoute _fromState(GoRouterState state) =>
      const CustomerOrdersRoute();

  @override
  String get location => GoRouteData.$location(
        '/customer/orders',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$CustomerOrderRoute on GoRouteData {
  static CustomerOrderRoute _fromState(GoRouterState state) =>
      CustomerOrderRoute(
        state.pathParameters['id']!,
      );

  CustomerOrderRoute get _self => this as CustomerOrderRoute;

  @override
  String get location => GoRouteData.$location(
        '/customer/orders/${Uri.encodeComponent(_self.id)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$CustomerSubscriptionRoute on GoRouteData {
  static CustomerSubscriptionRoute _fromState(GoRouterState state) =>
      CustomerSubscriptionRoute(
        state.pathParameters['id']!,
      );

  CustomerSubscriptionRoute get _self => this as CustomerSubscriptionRoute;

  @override
  String get location => GoRouteData.$location(
        '/customer/orders/subscriptions/${Uri.encodeComponent(_self.id)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$CustomerKhataRoute on GoRouteData {
  static CustomerKhataRoute _fromState(GoRouterState state) =>
      const CustomerKhataRoute();

  @override
  String get location => GoRouteData.$location(
        '/customer/khata',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$CustomerLedgerRoute on GoRouteData {
  static CustomerLedgerRoute _fromState(GoRouterState state) =>
      CustomerLedgerRoute(
        state.pathParameters['id']!,
      );

  CustomerLedgerRoute get _self => this as CustomerLedgerRoute;

  @override
  String get location => GoRouteData.$location(
        '/customer/khata/${Uri.encodeComponent(_self.id)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$CustomerServicesRoute on GoRouteData {
  static CustomerServicesRoute _fromState(GoRouterState state) =>
      const CustomerServicesRoute();

  @override
  String get location => GoRouteData.$location(
        '/customer/services',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$CustomerProfileRoute on GoRouteData {
  static CustomerProfileRoute _fromState(GoRouterState state) =>
      const CustomerProfileRoute();

  @override
  String get location => GoRouteData.$location(
        '/customer/profile',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $linkRoute => GoRouteData.$route(
      path: '/:kind/:id',
      factory: _$LinkRoute._fromState,
    );

mixin _$LinkRoute on GoRouteData {
  static LinkRoute _fromState(GoRouterState state) => LinkRoute(
        state.pathParameters['kind']!,
        state.pathParameters['id']!,
      );

  LinkRoute get _self => this as LinkRoute;

  @override
  String get location => GoRouteData.$location(
        '/${Uri.encodeComponent(_self.kind)}/${Uri.encodeComponent(_self.id)}',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
