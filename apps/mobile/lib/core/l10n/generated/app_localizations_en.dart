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
}
