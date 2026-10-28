// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Supply Biz';

  @override
  String get developmentEnvironment => 'Development environment';

  @override
  String get stagingEnvironment => 'Staging environment';

  @override
  String get productionEnvironment => 'Production environment';

  @override
  String get startupError => 'Something went wrong. Please try again.';

  @override
  String get networkUnavailable =>
      'Check your internet connection and try again.';

  @override
  String get networkTimeout => 'The request timed out. Please try again.';

  @override
  String get networkUnauthorized => 'Please sign in again to continue.';

  @override
  String get networkForbidden => 'You do not have access to this action.';

  @override
  String get networkPlanLocked => 'Upgrade your plan to use this feature.';

  @override
  String get networkNotFound => 'This item is no longer available.';

  @override
  String get networkConflict => 'This item has changed. Refresh and try again.';

  @override
  String get networkVersionConflict =>
      'A newer version is available. Refresh and try again.';

  @override
  String get networkValidation => 'Check the entered details and try again.';

  @override
  String get networkBusinessRule =>
      'This action could not be completed. Check the details and try again.';

  @override
  String get networkRateLimited =>
      'Too many requests. Please wait and try again.';

  @override
  String get networkServer =>
      'The service is temporarily unavailable. Please try again later.';

  @override
  String get routeLoading => 'Loading';

  @override
  String get routeLanguage => 'Choose your language';

  @override
  String get routeLogin => 'Sign in';

  @override
  String get routeOtp => 'Verify mobile number';

  @override
  String get routeRole => 'Choose your role';

  @override
  String get routeOnboarding => 'Set up your business';

  @override
  String get routeUpdate => 'Update required';

  @override
  String get routeLegal => 'Terms and privacy';

  @override
  String get routeNotifications => 'Notifications';

  @override
  String get routeSettings => 'Settings';

  @override
  String get routeSwitchRole => 'Switch role';

  @override
  String get routeSwitchMessage =>
      'Switch to the required role to open this link.';

  @override
  String get routeHomeAction => 'Back to home';

  @override
  String get routePlaceholder => 'This screen is being prepared.';

  @override
  String get navHome => 'Home';

  @override
  String get navOrders => 'Orders';

  @override
  String get navProducts => 'Products';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navMore => 'More';

  @override
  String get navKhata => 'Khata';

  @override
  String get navServices => 'Services';

  @override
  String get navProfile => 'Profile';

  @override
  String get routeOrder => 'Order details';

  @override
  String get routeSubscription => 'Subscription details';

  @override
  String get routeVendor => 'Vendor details';

  @override
  String get routeLedger => 'Vendor Khata';
}
