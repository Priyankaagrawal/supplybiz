import 'package:flutter/foundation.dart';

enum AppRole { vendor, customer }

enum OnboardingStep { category, business, kyc, status }

/// T-015/T-016/T-017 supply server-derived session and config state.
@immutable
class RouteAccess {
  const RouteAccess({
    this.initialized = true,
    this.forceUpdate = false,
    this.languageSelected = false,
    this.signedIn = false,
    this.activeRole,
    this.onboardingComplete = false,
    this.onboardingStep = OnboardingStep.category,
  });

  final bool initialized;
  final bool forceUpdate;
  final bool languageSelected;
  final bool signedIn;
  final AppRole? activeRole;
  final bool onboardingComplete;
  final OnboardingStep onboardingStep;

  String get home =>
      activeRole == AppRole.vendor ? '/vendor/home' : '/customer/home';
}

AppRole? routeRole(String path) {
  if (path.startsWith('/vendor/')) return AppRole.vendor;
  if (path.startsWith('/customer/')) return AppRole.customer;
  return null;
}

bool isEntryRoute(String path) => {
      '/',
      '/splash',
      '/language',
      '/login',
      '/otp',
      '/role',
      '/common/update',
      '/common/switch-role'
    }.contains(path);

/// Ordered guards from MOBILE_STRATEGY §3; no role or entitlement is granted here.
String? guardRedirect(RouteAccess access, String path) {
  String? unlessHere(String destination) =>
      path == destination ? null : destination;
  if (access.forceUpdate) return unlessHere('/common/update');
  if (!access.initialized) return unlessHere('/splash');
  if (path == '/common/legal') return null;
  if (!access.languageSelected) return unlessHere('/language');
  if (!access.signedIn) {
    return {'/language', '/login', '/otp'}.contains(path) ? null : '/login';
  }
  if (access.activeRole == null) return unlessHere('/role');
  if (access.activeRole == AppRole.vendor && !access.onboardingComplete) {
    return unlessHere('/vendor/onboarding/${access.onboardingStep.name}');
  }
  final requiredRole = routeRole(path);
  if (requiredRole != null && requiredRole != access.activeRole) {
    return '/common/switch-role';
  }
  if (isEntryRoute(path) || path.startsWith('/vendor/onboarding/')) {
    return unlessHere(access.home);
  }
  return null;
}
