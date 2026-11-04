import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/router/guards.dart';
import 'package:supplybiz_mobile/core/router/routing_controller.dart';

const id = '11111111-1111-4111-8111-111111111111';
const customer = RouteAccess(signedIn: true, activeRole: AppRole.customer);
const vendor = RouteAccess(
    signedIn: true, activeRole: AppRole.vendor, onboardingComplete: true);

void main() {
  test('T-013 guard order: update, startup, auth, role, onboarding, role match',
      () {
    expect(
        guardRedirect(const RouteAccess(forceUpdate: true, initialized: false),
            '/customer/home'),
        '/common/update');
    expect(guardRedirect(const RouteAccess(initialized: false), '/login'),
        '/splash');
    expect(guardRedirect(const RouteAccess(), '/customer/home'), '/login');
    expect(guardRedirect(const RouteAccess(), '/customer/home'), '/login');
    expect(guardRedirect(const RouteAccess(signedIn: true), '/customer/home'),
        '/role');
    expect(
        guardRedirect(
            const RouteAccess(
                signedIn: true,
                activeRole: AppRole.vendor,
                onboardingStep: OnboardingStep.kyc),
            '/customer/home'),
        '/vendor/onboarding/kyc');
    expect(guardRedirect(vendor, '/customer/home'), '/common/switch-role');
    expect(guardRedirect(customer, '/customer/home'), isNull);
    expect(guardRedirect(vendor, '/vendor/home'), isNull);
  });

  test(
      'T-013 entry screens and legal access do not loop or bypass force-update',
      () {
    expect(guardRedirect(const RouteAccess(), '/login'), isNull);
    expect(guardRedirect(const RouteAccess(), '/otp'), isNull);
    expect(guardRedirect(const RouteAccess(), '/common/legal'), isNull);
    expect(guardRedirect(const RouteAccess(forceUpdate: true), '/common/legal'),
        '/common/update');
    expect(guardRedirect(customer, '/login'), '/customer/home');
    expect(
        guardRedirect(vendor, '/vendor/onboarding/category'), '/vendor/home');
  });

  test(
      'T-013 pending link survives auth/role/onboarding gates, then is consumed once',
      () {
    final controller = RoutingController();
    addTearDown(controller.dispose);
    expect(controller.redirect(Uri.parse('/o/$id')), '/login');
    controller.update(const RouteAccess());
    expect(controller.redirect(Uri.parse('/login')), isNull);
    controller.update(const RouteAccess(signedIn: true));
    expect(controller.redirect(Uri.parse('/login')), '/role');
    controller
        .update(const RouteAccess(signedIn: true, activeRole: AppRole.vendor));
    expect(
        controller.redirect(Uri.parse('/role')), '/vendor/onboarding/category');
    controller.update(vendor);
    expect(controller.redirect(Uri.parse('/vendor/onboarding/category')),
        '/vendor/orders/$id');
    expect(controller.redirect(Uri.parse('/vendor/orders/$id')), isNull);
    expect(controller.redirect(Uri.parse('/vendor/products')), isNull);
  });

  test(
      'T-013 role mismatch prompts; explicit session update resumes; cancel returns home',
      () {
    final controller = RoutingController(access: vendor);
    addTearDown(controller.dispose);
    controller.openLink('supplybiz://v/$id');
    expect(
        controller.redirect(Uri.parse('/vendor/home')), '/common/switch-role');
    expect(controller.access.activeRole, AppRole.vendor);
    expect(controller.redirect(Uri.parse('/common/switch-role')), isNull);
    controller.update(customer);
    expect(controller.redirect(Uri.parse('/common/switch-role')),
        '/customer/home/vendors/$id');
    controller.update(vendor);
    controller.openLink('/khata/$id');
    expect(
        controller.redirect(Uri.parse('/vendor/home')), '/common/switch-role');
    controller.cancelPending();
    expect(
        controller.redirect(Uri.parse('/common/switch-role')), '/vendor/home');
  });

  test(
      'T-013 logout clears prior-user pending links; unknown/referral links go home',
      () {
    final controller = RoutingController(access: vendor);
    addTearDown(controller.dispose);
    controller.openLink('/v/$id');
    controller.update(const RouteAccess());
    controller.update(customer);
    expect(controller.redirect(Uri.parse('/login')), '/customer/home');
    controller.openLink('https://evil.example/o/$id');
    expect(
        controller.redirect(Uri.parse('/customer/orders')), '/customer/home');
    expect(controller.redirect(Uri.parse('/invite/FAKE'), unknown: true),
        '/customer/home');
  });
}
