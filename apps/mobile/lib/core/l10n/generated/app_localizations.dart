import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Supply Biz'**
  String get appName;

  /// No description provided for @developmentEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Development environment'**
  String get developmentEnvironment;

  /// No description provided for @stagingEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Staging environment'**
  String get stagingEnvironment;

  /// No description provided for @productionEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Production environment'**
  String get productionEnvironment;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get startupError;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get networkUnavailable;

  /// No description provided for @networkTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get networkTimeout;

  /// No description provided for @networkUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get networkUnauthorized;

  /// No description provided for @networkForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this action.'**
  String get networkForbidden;

  /// No description provided for @networkPlanLocked.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your plan to use this feature.'**
  String get networkPlanLocked;

  /// No description provided for @networkNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get networkNotFound;

  /// No description provided for @networkConflict.
  ///
  /// In en, this message translates to:
  /// **'This item has changed. Refresh and try again.'**
  String get networkConflict;

  /// No description provided for @networkVersionConflict.
  ///
  /// In en, this message translates to:
  /// **'A newer version is available. Refresh and try again.'**
  String get networkVersionConflict;

  /// No description provided for @networkValidation.
  ///
  /// In en, this message translates to:
  /// **'Check the entered details and try again.'**
  String get networkValidation;

  /// No description provided for @networkBusinessRule.
  ///
  /// In en, this message translates to:
  /// **'This action could not be completed. Check the details and try again.'**
  String get networkBusinessRule;

  /// No description provided for @networkRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait and try again.'**
  String get networkRateLimited;

  /// No description provided for @networkServer.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable. Please try again later.'**
  String get networkServer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
