import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @homeChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get homeChooseLocation;

  /// No description provided for @homeLocation.
  ///
  /// In en, this message translates to:
  /// **'{area}, {city} · {pincode}'**
  String homeLocation(String area, String city, String pincode);

  /// No description provided for @homeLocationHelp.
  ///
  /// In en, this message translates to:
  /// **'Use this location to find vendors. Manage delivery addresses separately in Addresses.'**
  String get homeLocationHelp;

  /// No description provided for @homeArea.
  ///
  /// In en, this message translates to:
  /// **'Area or address (required)'**
  String get homeArea;

  /// No description provided for @homeUseLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get homeUseLocation;

  /// No description provided for @homeSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Choose a saved address'**
  String get homeSavedAddresses;

  /// No description provided for @homeSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search vendors and products'**
  String get homeSearchTitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find vendors by name or by products they carry.'**
  String get homeSearchHint;

  /// No description provided for @homeSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchAction;

  /// No description provided for @homeRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get homeRecentSearches;

  /// No description provided for @homeSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vendors match in this area. Try another search or change your location.'**
  String get homeSearchEmpty;

  /// No description provided for @homeLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a location to search for vendors.'**
  String get homeLocationRequired;

  /// No description provided for @homeDistance.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String homeDistance(String distance);

  /// No description provided for @homeUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String homeUnread(int count);

  /// No description provided for @homeRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh home'**
  String get homeRefresh;

  /// No description provided for @homeStale.
  ///
  /// In en, this message translates to:
  /// **'Showing the last loaded home. Refresh online for current delivery statuses.'**
  String get homeStale;

  /// No description provided for @homeCategories.
  ///
  /// In en, this message translates to:
  /// **'Supply categories'**
  String get homeCategories;

  /// No description provided for @homeNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No supply categories are available yet.'**
  String get homeNoCategories;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{name} — Coming soon'**
  String homeComingSoon(String name);

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s deliveries'**
  String get homeToday;

  /// No description provided for @homeNoDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No deliveries today. Browse the supply categories to find vendors.'**
  String get homeNoDeliveries;

  /// No description provided for @homeVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get homeVendor;

  /// No description provided for @homeOrder.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String homeOrder(String number);

  /// No description provided for @homeProduct.
  ///
  /// In en, this message translates to:
  /// **'{name} × {qty}'**
  String homeProduct(String name, int qty);

  /// No description provided for @homeMoreDeliveries.
  ///
  /// In en, this message translates to:
  /// **'More deliveries'**
  String get homeMoreDeliveries;

  /// No description provided for @homeMoreVendors.
  ///
  /// In en, this message translates to:
  /// **'More vendors'**
  String get homeMoreVendors;

  /// No description provided for @homeStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get homeStatusNew;

  /// No description provided for @homeStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get homeStatusAccepted;

  /// No description provided for @homeStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get homeStatusPreparing;

  /// No description provided for @homeStatusOut.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get homeStatusOut;

  /// No description provided for @homeStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get homeStatusDelivered;

  /// No description provided for @homeStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get homeStatusRejected;

  /// No description provided for @homeStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get homeStatusCancelled;

  /// No description provided for @homeStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get homeStatusFailed;

  /// No description provided for @homeStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get homeStatusUnknown;

  /// No description provided for @addressTitle.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addressTitle;

  /// No description provided for @addressAdd.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addressAdd;

  /// No description provided for @addressEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get addressEdit;

  /// No description provided for @addressSave.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get addressSave;

  /// No description provided for @addressDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete address'**
  String get addressDelete;

  /// No description provided for @addressDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {label}? If it is your default address, another saved address will become default.'**
  String addressDeleteConfirm(String label);

  /// No description provided for @addressEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses. Add an address for deliveries.'**
  String get addressEmpty;

  /// No description provided for @addressDefault.
  ///
  /// In en, this message translates to:
  /// **'Default address'**
  String get addressDefault;

  /// No description provided for @addressMakeDefault.
  ///
  /// In en, this message translates to:
  /// **'Use as default address'**
  String get addressMakeDefault;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Label (required)'**
  String get addressLabel;

  /// No description provided for @addressHouse.
  ///
  /// In en, this message translates to:
  /// **'House or flat (required)'**
  String get addressHouse;

  /// No description provided for @addressArea.
  ///
  /// In en, this message translates to:
  /// **'Street or area (required)'**
  String get addressArea;

  /// No description provided for @addressLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark (optional)'**
  String get addressLandmark;

  /// No description provided for @addressCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Latitude {latitude}, longitude {longitude}'**
  String addressCoordinates(String latitude, String longitude);

  /// No description provided for @addressStale.
  ///
  /// In en, this message translates to:
  /// **'Refresh online before changing addresses. Displayed addresses may be out of date.'**
  String get addressStale;

  /// No description provided for @addressPending.
  ///
  /// In en, this message translates to:
  /// **'An address request needs confirmation. Retry the saved request before making another change.'**
  String get addressPending;

  /// No description provided for @addressExpired.
  ///
  /// In en, this message translates to:
  /// **'The retry window has ended. Refresh and review your addresses, then dismiss the saved request before making another change.'**
  String get addressExpired;

  /// No description provided for @addressDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss saved request'**
  String get addressDismiss;

  /// No description provided for @addressDefaultRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose another default address before clearing this default.'**
  String get addressDefaultRequired;

  /// No description provided for @customersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get customersAdd;

  /// No description provided for @customersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get customersEdit;

  /// No description provided for @customersView.
  ///
  /// In en, this message translates to:
  /// **'View customer'**
  String get customersView;

  /// No description provided for @customersDetail.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get customersDetail;

  /// No description provided for @customersSave.
  ///
  /// In en, this message translates to:
  /// **'Save customer'**
  String get customersSave;

  /// No description provided for @customersConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get customersConfirm;

  /// No description provided for @customersSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer saved.'**
  String get customersSaved;

  /// No description provided for @customersName.
  ///
  /// In en, this message translates to:
  /// **'Name (required)'**
  String get customersName;

  /// No description provided for @customersMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile (required)'**
  String get customersMobile;

  /// No description provided for @customersEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get customersEmail;

  /// No description provided for @customersAddress.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get customersAddress;

  /// No description provided for @customersPayment.
  ///
  /// In en, this message translates to:
  /// **'Preferred payment method'**
  String get customersPayment;

  /// No description provided for @customersCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get customersCash;

  /// No description provided for @customersUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get customersUpi;

  /// No description provided for @customersBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get customersBank;

  /// No description provided for @customersWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get customersWallet;

  /// No description provided for @customersInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value.'**
  String get customersInvalid;

  /// No description provided for @customersAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get customersAll;

  /// No description provided for @customersActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customersActive;

  /// No description provided for @customersInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get customersInactive;

  /// No description provided for @customersSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get customersSubscribed;

  /// No description provided for @customersSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name or mobile'**
  String get customersSearch;

  /// No description provided for @customersFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter customers'**
  String get customersFilter;

  /// No description provided for @customersMore.
  ///
  /// In en, this message translates to:
  /// **'Show more customers'**
  String get customersMore;

  /// No description provided for @customersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No customers match. Add a customer or change your filters.'**
  String get customersEmpty;

  /// No description provided for @customersOfflineAccount.
  ///
  /// In en, this message translates to:
  /// **'Offline customer'**
  String get customersOfflineAccount;

  /// No description provided for @customersLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked app account'**
  String get customersLinked;

  /// No description provided for @customersNotFound.
  ///
  /// In en, this message translates to:
  /// **'This customer is not available.'**
  String get customersNotFound;

  /// No description provided for @customersNoAddress.
  ///
  /// In en, this message translates to:
  /// **'No address added.'**
  String get customersNoAddress;

  /// No description provided for @customersCall.
  ///
  /// In en, this message translates to:
  /// **'Call customer'**
  String get customersCall;

  /// No description provided for @customersDialUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A phone app could not be opened.'**
  String get customersDialUnavailable;

  /// No description provided for @customersDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Mark inactive'**
  String get customersDeactivate;

  /// No description provided for @customersReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate customer'**
  String get customersReactivate;

  /// No description provided for @customersStatusConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change the status of {name}?'**
  String customersStatusConfirm(String name);

  /// No description provided for @customersKeepHistory.
  ///
  /// In en, this message translates to:
  /// **'The customer will stop counting toward your limit. Their history will be kept.'**
  String get customersKeepHistory;

  /// No description provided for @customersCheckCapacity.
  ///
  /// In en, this message translates to:
  /// **'Reactivation counts toward your active customer limit.'**
  String get customersCheckCapacity;

  /// No description provided for @customersCapacity.
  ///
  /// In en, this message translates to:
  /// **'{count} active customers · limit {limit}'**
  String customersCapacity(int count, int limit);

  /// No description provided for @customersDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This mobile number is already in your customer list.'**
  String get customersDuplicate;

  /// No description provided for @customersLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Your active customer limit has been reached. Mark a customer inactive or contact support about a plan change.'**
  String get customersLimitReached;

  /// No description provided for @customersLinkedMobile.
  ///
  /// In en, this message translates to:
  /// **'The mobile number of a linked app account cannot be changed.'**
  String get customersLinkedMobile;

  /// No description provided for @customersOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing saved customers. Changes are unavailable until you refresh online.'**
  String get customersOffline;

  /// No description provided for @customersPending.
  ///
  /// In en, this message translates to:
  /// **'A saved request needs confirmation. Retry it before making another change.'**
  String get customersPending;

  /// No description provided for @customersRetrySaved.
  ///
  /// In en, this message translates to:
  /// **'Retry saved request'**
  String get customersRetrySaved;

  /// No description provided for @customersActivityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Customer activity details are not available yet.'**
  String get customersActivityUnavailable;

  /// No description provided for @customersAddOrder.
  ///
  /// In en, this message translates to:
  /// **'Add order'**
  String get customersAddOrder;

  /// No description provided for @customersOrders.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get customersOrders;

  /// No description provided for @customersSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Current subscription'**
  String get customersSubscriptions;

  /// No description provided for @customersPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get customersPayments;

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

  /// No description provided for @routeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get routeLoading;

  /// No description provided for @routeLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get routeLogin;

  /// No description provided for @routeOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify mobile number'**
  String get routeOtp;

  /// No description provided for @routeRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get routeRole;

  /// No description provided for @routeOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Set up your business'**
  String get routeOnboarding;

  /// No description provided for @routeUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get routeUpdate;

  /// No description provided for @routeLegal.
  ///
  /// In en, this message translates to:
  /// **'Terms and privacy'**
  String get routeLegal;

  /// No description provided for @routeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get routeNotifications;

  /// No description provided for @routeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get routeSettings;

  /// No description provided for @routeSwitchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch role'**
  String get routeSwitchRole;

  /// No description provided for @routeSwitchMessage.
  ///
  /// In en, this message translates to:
  /// **'Switch to the required role to open this link.'**
  String get routeSwitchMessage;

  /// No description provided for @routeHomeAction.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get routeHomeAction;

  /// No description provided for @routePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This screen is being prepared.'**
  String get routePlaceholder;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navKhata.
  ///
  /// In en, this message translates to:
  /// **'Khata'**
  String get navKhata;

  /// No description provided for @navServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navServices;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @routeOrder.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get routeOrder;

  /// No description provided for @routeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription details'**
  String get routeSubscription;

  /// No description provided for @routeVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor details'**
  String get routeVendor;

  /// No description provided for @routeLedger.
  ///
  /// In en, this message translates to:
  /// **'Vendor Khata'**
  String get routeLedger;

  /// No description provided for @authMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get authMobile;

  /// No description provided for @authInvalidMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number starting with 6–9.'**
  String get authInvalidMobile;

  /// No description provided for @authConsent.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms and Privacy Policy.'**
  String get authConsent;

  /// No description provided for @authTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get authTerms;

  /// No description provided for @authPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacy;

  /// No description provided for @authSend.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get authSend;

  /// No description provided for @authWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Continue with WhatsApp'**
  String get authWhatsapp;

  /// No description provided for @authSms.
  ///
  /// In en, this message translates to:
  /// **'Sent via SMS'**
  String get authSms;

  /// No description provided for @authCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit verification code'**
  String get authCode;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authResend.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get authResend;

  /// No description provided for @authResendWait.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String authResendWait(int seconds);

  /// No description provided for @authChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get authChangeNumber;

  /// No description provided for @authWrongOtp.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code. Please try again.'**
  String get authWrongOtp;

  /// No description provided for @authExpiredOtp.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Please request a new one.'**
  String get authExpiredOtp;

  /// No description provided for @authExhaustedOtp.
  ///
  /// In en, this message translates to:
  /// **'Too many incorrect attempts. Please request a new code.'**
  String get authExhaustedOtp;

  /// No description provided for @authDeliveryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'OTP delivery is unavailable. Please try again later.'**
  String get authDeliveryUnavailable;

  /// No description provided for @authLegalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy Policy are unavailable. Please try again later.'**
  String get authLegalUnavailable;

  /// No description provided for @authCustomer.
  ///
  /// In en, this message translates to:
  /// **'I want to buy'**
  String get authCustomer;

  /// No description provided for @authVendor.
  ///
  /// In en, this message translates to:
  /// **'I sell / supply'**
  String get authVendor;

  /// No description provided for @authLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get authLogout;

  /// No description provided for @authLogoutAll.
  ///
  /// In en, this message translates to:
  /// **'Logout from all devices'**
  String get authLogoutAll;

  /// No description provided for @authRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get authRetry;

  /// No description provided for @authTrust.
  ///
  /// In en, this message translates to:
  /// **'Secure Registration • Quick & Easy Setup • Start Supplying Today'**
  String get authTrust;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update Supply Biz to continue.'**
  String get updateRequired;

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// No description provided for @updateStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store could not be opened. Try again when it is available.'**
  String get updateStoreUnavailable;

  /// No description provided for @configUnavailable.
  ///
  /// In en, this message translates to:
  /// **'App configuration is unavailable. Check your connection and try again.'**
  String get configUnavailable;

  /// No description provided for @onboardingInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value.'**
  String get onboardingInvalid;

  /// No description provided for @onboardingAccountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Account numbers must match.'**
  String get onboardingAccountMismatch;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 4'**
  String onboardingStep(int step);

  /// No description provided for @onboardingCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose your business category'**
  String get onboardingCategory;

  /// No description provided for @onboardingNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories are available. Try again later.'**
  String get onboardingNoCategories;

  /// No description provided for @onboardingBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get onboardingBusinessName;

  /// No description provided for @onboardingGstin.
  ///
  /// In en, this message translates to:
  /// **'GSTIN (optional)'**
  String get onboardingGstin;

  /// No description provided for @onboardingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shop address'**
  String get onboardingAddress;

  /// No description provided for @onboardingCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get onboardingCity;

  /// No description provided for @onboardingState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get onboardingState;

  /// No description provided for @onboardingPincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get onboardingPincode;

  /// No description provided for @onboardingLatitude.
  ///
  /// In en, this message translates to:
  /// **'Shop latitude'**
  String get onboardingLatitude;

  /// No description provided for @onboardingLongitude.
  ///
  /// In en, this message translates to:
  /// **'Shop longitude'**
  String get onboardingLongitude;

  /// No description provided for @onboardingShopPhoto.
  ///
  /// In en, this message translates to:
  /// **'Shop photo'**
  String get onboardingShopPhoto;

  /// No description provided for @onboardingAadhaarFront.
  ///
  /// In en, this message translates to:
  /// **'Masked Aadhaar front'**
  String get onboardingAadhaarFront;

  /// No description provided for @onboardingAadhaarBack.
  ///
  /// In en, this message translates to:
  /// **'Masked Aadhaar back'**
  String get onboardingAadhaarBack;

  /// No description provided for @onboardingPanPhoto.
  ///
  /// In en, this message translates to:
  /// **'PAN document'**
  String get onboardingPanPhoto;

  /// No description provided for @onboardingPan.
  ///
  /// In en, this message translates to:
  /// **'PAN number'**
  String get onboardingPan;

  /// No description provided for @onboardingHolder.
  ///
  /// In en, this message translates to:
  /// **'Account holder name'**
  String get onboardingHolder;

  /// No description provided for @onboardingBank.
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get onboardingBank;

  /// No description provided for @onboardingAccount.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get onboardingAccount;

  /// No description provided for @onboardingConfirmAccount.
  ///
  /// In en, this message translates to:
  /// **'Confirm account number'**
  String get onboardingConfirmAccount;

  /// No description provided for @onboardingIfsc.
  ///
  /// In en, this message translates to:
  /// **'IFSC'**
  String get onboardingIfsc;

  /// No description provided for @onboardingUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI ID (optional)'**
  String get onboardingUpi;

  /// No description provided for @onboardingSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Used only for verification. Screenshots are blocked on these screens.'**
  String get onboardingSecurityNote;

  /// No description provided for @onboardingMaskGuide.
  ///
  /// In en, this message translates to:
  /// **'Hide the first 8 Aadhaar digits everywhere on the document, including any reverse-side copies. Supply an already masked document or use the image masking tool. Do not upload a full Aadhaar number.'**
  String get onboardingMaskGuide;

  /// No description provided for @onboardingMaskedPdf.
  ///
  /// In en, this message translates to:
  /// **'PDFs must already be masked. Check every page before choosing this file.'**
  String get onboardingMaskedPdf;

  /// No description provided for @onboardingMaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'I confirm that all Aadhaar numbers have their first 8 digits hidden.'**
  String get onboardingMaskConfirm;

  /// No description provided for @onboardingMaskTool.
  ///
  /// In en, this message translates to:
  /// **'Add a black masking rectangle'**
  String get onboardingMaskTool;

  /// No description provided for @onboardingMaskX.
  ///
  /// In en, this message translates to:
  /// **'Mask horizontal position'**
  String get onboardingMaskX;

  /// No description provided for @onboardingMaskY.
  ///
  /// In en, this message translates to:
  /// **'Mask vertical position'**
  String get onboardingMaskY;

  /// No description provided for @onboardingMaskWidth.
  ///
  /// In en, this message translates to:
  /// **'Mask width'**
  String get onboardingMaskWidth;

  /// No description provided for @onboardingMaskHeight.
  ///
  /// In en, this message translates to:
  /// **'Mask height'**
  String get onboardingMaskHeight;

  /// No description provided for @onboardingUseDocument.
  ///
  /// In en, this message translates to:
  /// **'Use masked document'**
  String get onboardingUseDocument;

  /// No description provided for @onboardingClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get onboardingClose;

  /// No description provided for @onboardingFileError.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid JPG, PNG or PDF up to 5 MB (images up to 20 megapixels).'**
  String get onboardingFileError;

  /// No description provided for @onboardingSecureError.
  ///
  /// In en, this message translates to:
  /// **'Screen protection is unavailable. Retry before entering verification details.'**
  String get onboardingSecureError;

  /// No description provided for @onboardingPreviewError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the attachment. Try again.'**
  String get onboardingPreviewError;

  /// No description provided for @onboardingDocumentsRequired.
  ///
  /// In en, this message translates to:
  /// **'Attach all three verification documents.'**
  String get onboardingDocumentsRequired;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for verification'**
  String get onboardingSubmit;

  /// No description provided for @onboardingEditBusiness.
  ///
  /// In en, this message translates to:
  /// **'Edit business details'**
  String get onboardingEditBusiness;

  /// No description provided for @onboardingResubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit verification'**
  String get onboardingResubmit;

  /// No description provided for @onboardingRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get onboardingRefresh;

  /// No description provided for @onboardingVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified by manual review'**
  String get onboardingVerified;

  /// No description provided for @onboardingRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification rejected'**
  String get onboardingRejected;

  /// No description provided for @onboardingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting manual review'**
  String get onboardingReview;

  /// No description provided for @onboardingNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get onboardingNotVerified;

  /// No description provided for @onboardingHidden.
  ///
  /// In en, this message translates to:
  /// **'Your shop is hidden from customer discovery until verification is approved.'**
  String get onboardingHidden;

  /// No description provided for @onboardingManualMethod.
  ///
  /// In en, this message translates to:
  /// **'Verification method: manual review'**
  String get onboardingManualMethod;

  /// No description provided for @onboardingProviderNotRun.
  ///
  /// In en, this message translates to:
  /// **'Automated provider checks: NOT_RUN'**
  String get onboardingProviderNotRun;

  /// No description provided for @onboardingMaskedAccount.
  ///
  /// In en, this message translates to:
  /// **'Account ending {last4}'**
  String onboardingMaskedAccount(String last4);

  /// No description provided for @onboardingUpload.
  ///
  /// In en, this message translates to:
  /// **'Choose / replace {label}'**
  String onboardingUpload(String label);

  /// No description provided for @onboardingView.
  ///
  /// In en, this message translates to:
  /// **'View {label}'**
  String onboardingView(String label);

  /// No description provided for @onboardingRetryUpload.
  ///
  /// In en, this message translates to:
  /// **'Retry upload: {label}'**
  String onboardingRetryUpload(String label);

  /// No description provided for @areaLocation.
  ///
  /// In en, this message translates to:
  /// **'Shop location'**
  String get areaLocation;

  /// No description provided for @areaSaveCoverage.
  ///
  /// In en, this message translates to:
  /// **'Save coverage'**
  String get areaSaveCoverage;

  /// No description provided for @areaCoverage.
  ///
  /// In en, this message translates to:
  /// **'Delivery coverage'**
  String get areaCoverage;

  /// No description provided for @areaGps.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get areaGps;

  /// No description provided for @areaTitle.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get areaTitle;

  /// No description provided for @areaBusinessRequired.
  ///
  /// In en, this message translates to:
  /// **'Complete business details in onboarding before setting a location.'**
  String get areaBusinessRequired;

  /// No description provided for @areaGpsError.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable or permission denied. Enter coordinates manually or try again.'**
  String get areaGpsError;

  /// No description provided for @areaPincodes.
  ///
  /// In en, this message translates to:
  /// **'Additional pincodes (separate with commas)'**
  String get areaPincodes;

  /// No description provided for @areaExplanation.
  ///
  /// In en, this message translates to:
  /// **'Coverage includes customers within the radius OR an additional pincode. Leave radius blank for pincodes only. Save shop location separately before changing coverage.'**
  String get areaExplanation;

  /// No description provided for @areaSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to server.'**
  String get areaSaved;

  /// No description provided for @areaReverification.
  ///
  /// In en, this message translates to:
  /// **'Changing verified business details requires re-verification. Your saved details have not changed.'**
  String get areaReverification;

  /// No description provided for @areaRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius in km (1–20, optional)'**
  String get areaRadius;

  /// No description provided for @areaInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a radius from 1 to 20 and/or unique six-digit Indian pincodes.'**
  String get areaInvalid;

  /// No description provided for @areaSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save shop location'**
  String get areaSaveLocation;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @productsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productsAdd;

  /// No description provided for @productsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productsEdit;

  /// No description provided for @productsSave.
  ///
  /// In en, this message translates to:
  /// **'Save product'**
  String get productsSave;

  /// No description provided for @productsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search products by name'**
  String get productsSearch;

  /// No description provided for @productsFilter.
  ///
  /// In en, this message translates to:
  /// **'Product type filter'**
  String get productsFilter;

  /// No description provided for @productsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get productsAll;

  /// No description provided for @productsMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get productsMilk;

  /// No description provided for @productsPaneer.
  ///
  /// In en, this message translates to:
  /// **'Paneer'**
  String get productsPaneer;

  /// No description provided for @productsCurd.
  ///
  /// In en, this message translates to:
  /// **'Curd'**
  String get productsCurd;

  /// No description provided for @productsOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get productsOther;

  /// No description provided for @productsGhee.
  ///
  /// In en, this message translates to:
  /// **'Ghee'**
  String get productsGhee;

  /// No description provided for @productsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products found. Add a product or change your search.'**
  String get productsEmpty;

  /// No description provided for @productsOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing your saved catalog. Refresh online before making changes. Photos may be unavailable offline.'**
  String get productsOffline;

  /// No description provided for @productsPending.
  ///
  /// In en, this message translates to:
  /// **'A saved request needs confirmation. Retry it before making another change.'**
  String get productsPending;

  /// No description provided for @productsRetryPending.
  ///
  /// In en, this message translates to:
  /// **'Retry saved request'**
  String get productsRetryPending;

  /// No description provided for @productsName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productsName;

  /// No description provided for @productsType.
  ///
  /// In en, this message translates to:
  /// **'Product type'**
  String get productsType;

  /// No description provided for @productsMilkType.
  ///
  /// In en, this message translates to:
  /// **'Milk type'**
  String get productsMilkType;

  /// No description provided for @productsCow.
  ///
  /// In en, this message translates to:
  /// **'Cow'**
  String get productsCow;

  /// No description provided for @productsBuffalo.
  ///
  /// In en, this message translates to:
  /// **'Buffalo'**
  String get productsBuffalo;

  /// No description provided for @productsToned.
  ///
  /// In en, this message translates to:
  /// **'Toned'**
  String get productsToned;

  /// No description provided for @productsDoubleToned.
  ///
  /// In en, this message translates to:
  /// **'Double toned'**
  String get productsDoubleToned;

  /// No description provided for @productsFullCream.
  ///
  /// In en, this message translates to:
  /// **'Full cream'**
  String get productsFullCream;

  /// No description provided for @productsUnitValue.
  ///
  /// In en, this message translates to:
  /// **'Pack size (up to 3 decimal places)'**
  String get productsUnitValue;

  /// No description provided for @productsUnit250.
  ///
  /// In en, this message translates to:
  /// **'250 ml'**
  String get productsUnit250;

  /// No description provided for @productsUnit500.
  ///
  /// In en, this message translates to:
  /// **'500 ml'**
  String get productsUnit500;

  /// No description provided for @productsUnitLitre.
  ///
  /// In en, this message translates to:
  /// **'1 L'**
  String get productsUnitLitre;

  /// No description provided for @productsUnitType.
  ///
  /// In en, this message translates to:
  /// **'Pack unit'**
  String get productsUnitType;

  /// No description provided for @productsSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling price (₹)'**
  String get productsSellingPrice;

  /// No description provided for @productsSubscriptionPrice.
  ///
  /// In en, this message translates to:
  /// **'Subscription price (₹, optional)'**
  String get productsSubscriptionPrice;

  /// No description provided for @productsStock.
  ///
  /// In en, this message translates to:
  /// **'Stock (packs)'**
  String get productsStock;

  /// No description provided for @productsMoq.
  ///
  /// In en, this message translates to:
  /// **'Minimum order (packs)'**
  String get productsMoq;

  /// No description provided for @productsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get productsDescription;

  /// No description provided for @productsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get productsActive;

  /// No description provided for @productsInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get productsInactive;

  /// No description provided for @productsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get productsDelete;

  /// No description provided for @productsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this product? Its stock and sales history will be kept.'**
  String get productsDeleteConfirm;

  /// No description provided for @productsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get productsCancel;

  /// No description provided for @productsInUse.
  ///
  /// In en, this message translates to:
  /// **'This product has active or paused subscriptions. End those subscriptions before deleting it. You can deactivate it instead.'**
  String get productsInUse;

  /// No description provided for @productsInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Stock cannot be reduced below zero. Refresh and check the quantity.'**
  String get productsInsufficient;

  /// No description provided for @productsAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get productsAdjust;

  /// No description provided for @productsDelta.
  ///
  /// In en, this message translates to:
  /// **'Change in packs (for example, -2 or 5)'**
  String get productsDelta;

  /// No description provided for @productsReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for adjustment'**
  String get productsReason;

  /// No description provided for @productsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply adjustment'**
  String get productsApply;

  /// No description provided for @productsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the name, pack size, whole-pack quantities and prices. Subscription price must not exceed selling price.'**
  String get productsInvalid;

  /// No description provided for @productsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get productsPhoto;

  /// No description provided for @productsChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose product photo'**
  String get productsChoosePhoto;

  /// No description provided for @productsRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get productsRemovePhoto;

  /// No description provided for @productsPhotoOnly.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPEG or PNG image up to 5 MB.'**
  String get productsPhotoOnly;

  /// No description provided for @productsPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Product photo unavailable'**
  String get productsPhotoUnavailable;

  /// No description provided for @productsNoTypes.
  ///
  /// In en, this message translates to:
  /// **'No product types are configured for your category. Contact support.'**
  String get productsNoTypes;

  /// No description provided for @productsStockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock: {quantity} packs'**
  String productsStockValue(int quantity);

  /// No description provided for @notificationsReadItem.
  ///
  /// In en, this message translates to:
  /// **'Read notification'**
  String get notificationsReadItem;

  /// No description provided for @notificationsNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsNow;

  /// No description provided for @notificationsUnreadItem.
  ///
  /// In en, this message translates to:
  /// **'Unread notification'**
  String get notificationsUnreadItem;

  /// No description provided for @notificationsHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String notificationsHours(int count);

  /// No description provided for @notificationsClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications for this role?'**
  String get notificationsClearConfirm;

  /// No description provided for @notificationsContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get notificationsContinue;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notificationsUnread(int count);

  /// No description provided for @notificationsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Push preferences'**
  String get notificationsPreferences;

  /// No description provided for @notificationsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this notification. Refresh the inbox and try again.'**
  String get notificationsOpenFailed;

  /// No description provided for @notificationsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Alerts are blocked. You can allow notifications in Android Settings. Your inbox still works.'**
  String get notificationsPermissionDenied;

  /// No description provided for @notificationsPermissionAllowed.
  ///
  /// In en, this message translates to:
  /// **'Permission allowed. Alerts will be available after device registration succeeds.'**
  String get notificationsPermissionAllowed;

  /// No description provided for @notificationsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view notifications.'**
  String get notificationsSignIn;

  /// No description provided for @notificationsPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Enable alerts for orders, payments and account updates? Android will ask for notification permission after you continue. Your inbox works without alerts.'**
  String get notificationsPermissionBody;

  /// No description provided for @notificationsMandatory.
  ///
  /// In en, this message translates to:
  /// **'Preferences affect optional push alerts only. Security and KYC updates remain enabled. Inbox items are kept for 90 days.'**
  String get notificationsMandatory;

  /// No description provided for @notificationsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notificationsSystem;

  /// No description provided for @notificationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Push alerts are unavailable in this build. The inbox and preferences still work.'**
  String get notificationsUnavailable;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications in this category.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsRetrySaved.
  ///
  /// In en, this message translates to:
  /// **'Retry saved action'**
  String get notificationsRetrySaved;

  /// No description provided for @notificationsMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String notificationsMinutes(int count);

  /// No description provided for @notificationsDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get notificationsDelivery;

  /// No description provided for @notificationsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationsOpen;

  /// No description provided for @notificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable push alerts'**
  String get notificationsEnable;

  /// No description provided for @notificationsPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get notificationsPayments;

  /// No description provided for @notificationsVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get notificationsVendor;

  /// No description provided for @notificationsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get notificationsCustomer;

  /// No description provided for @notificationsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get notificationsCancel;

  /// No description provided for @notificationsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsAll;

  /// No description provided for @notificationsSwitchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch to {role} to open this notification?'**
  String notificationsSwitchRole(String role);

  /// No description provided for @notificationsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get notificationsRefresh;

  /// No description provided for @notificationsReadAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsReadAll;

  /// No description provided for @notificationsNew.
  ///
  /// In en, this message translates to:
  /// **'You have a new notification.'**
  String get notificationsNew;

  /// No description provided for @notificationsDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String notificationsDays(int count);

  /// No description provided for @notificationsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get notificationsClear;

  /// No description provided for @discoveryVendors.
  ///
  /// In en, this message translates to:
  /// **'Browse vendors'**
  String get discoveryVendors;

  /// No description provided for @discoveryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get discoveryFavorites;

  /// No description provided for @discoverySort.
  ///
  /// In en, this message translates to:
  /// **'Sort vendors'**
  String get discoverySort;

  /// No description provided for @discoveryNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get discoveryNearby;

  /// No description provided for @discoveryPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get discoveryPopular;

  /// No description provided for @discoveryNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite vendors available here.'**
  String get discoveryNoFavorites;

  /// No description provided for @discoveryOpenVendor.
  ///
  /// In en, this message translates to:
  /// **'View vendor'**
  String get discoveryOpenVendor;

  /// No description provided for @discoveryFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get discoveryFavorite;

  /// No description provided for @discoveryUnfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get discoveryUnfavorite;

  /// No description provided for @discoveryAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get discoveryAbout;

  /// No description provided for @discoveryDeliveryCharge.
  ///
  /// In en, this message translates to:
  /// **'Delivery charge: {amount}'**
  String discoveryDeliveryCharge(String amount);

  /// No description provided for @discoveryMinimumOrder.
  ///
  /// In en, this message translates to:
  /// **'Minimum order: {amount}'**
  String discoveryMinimumOrder(String amount);

  /// No description provided for @discoveryHoursUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Opening hours are unavailable.'**
  String get discoveryHoursUnavailable;

  /// No description provided for @discoveryHolidays.
  ///
  /// In en, this message translates to:
  /// **'Upcoming holidays'**
  String get discoveryHolidays;

  /// No description provided for @discoveryNoHolidays.
  ///
  /// In en, this message translates to:
  /// **'No upcoming holidays listed.'**
  String get discoveryNoHolidays;

  /// No description provided for @discoverySubscriptionInfo.
  ///
  /// In en, this message translates to:
  /// **'Subscription prices are shown per pack. Subscription setup will be available separately.'**
  String get discoverySubscriptionInfo;

  /// No description provided for @discoveryNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products available.'**
  String get discoveryNoProducts;

  /// No description provided for @discoveryOpenProduct.
  ///
  /// In en, this message translates to:
  /// **'View product'**
  String get discoveryOpenProduct;

  /// No description provided for @discoveryPack.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit} per pack'**
  String discoveryPack(String value, String unit);

  /// No description provided for @discoveryMoq.
  ///
  /// In en, this message translates to:
  /// **'Minimum quantity: {qty}'**
  String discoveryMoq(int qty);

  /// No description provided for @discoveryOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get discoveryOutOfStock;

  /// No description provided for @discoveryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {qty}'**
  String discoveryQuantity(int qty);

  /// No description provided for @discoveryDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get discoveryDecrease;

  /// No description provided for @discoveryIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get discoveryIncrease;

  /// No description provided for @discoveryAddCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get discoveryAddCart;

  /// No description provided for @discoveryChanged.
  ///
  /// In en, this message translates to:
  /// **'Product details changed. Review the updated price and quantity before adding.'**
  String get discoveryChanged;

  /// No description provided for @discoveryReplaceCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart contains another vendor. Replace it with this vendor?'**
  String get discoveryReplaceCart;

  /// No description provided for @discoveryAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to cart.'**
  String get discoveryAdded;

  /// No description provided for @discoveryCartError.
  ///
  /// In en, this message translates to:
  /// **'Could not add this quantity. Review stock and try again.'**
  String get discoveryCartError;

  /// No description provided for @discoveryCart.
  ///
  /// In en, this message translates to:
  /// **'Cart ({count} items)'**
  String discoveryCart(int count);

  /// No description provided for @discoveryCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get discoveryCartEmpty;

  /// No description provided for @discoveryCartNotice.
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Prices and availability will be checked at checkout.'**
  String get discoveryCartNotice;

  /// No description provided for @discoveryClearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get discoveryClearCart;

  /// No description provided for @discoveryClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove all items from your cart?'**
  String get discoveryClearConfirm;

  /// No description provided for @discoveryRetryPending.
  ///
  /// In en, this message translates to:
  /// **'A favorite update is awaiting confirmation. Retry the saved update before changing another favorite.'**
  String get discoveryRetryPending;

  /// No description provided for @discoveryRetryExpired.
  ///
  /// In en, this message translates to:
  /// **'This saved update is older than 24 hours. Refresh favorites before making another change.'**
  String get discoveryRetryExpired;

  /// No description provided for @discoveryDismiss.
  ///
  /// In en, this message translates to:
  /// **'Refresh favorites'**
  String get discoveryDismiss;

  /// No description provided for @discoveryDismissConfirm.
  ///
  /// In en, this message translates to:
  /// **'Refresh favorites to check the current state and clear this expired update?'**
  String get discoveryDismissConfirm;

  /// No description provided for @discoveryImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get discoveryImageUnavailable;

  /// No description provided for @discoveryImage.
  ///
  /// In en, this message translates to:
  /// **'Vendor or product image'**
  String get discoveryImage;

  /// No description provided for @discoverySubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get discoverySubscription;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart and checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutNew.
  ///
  /// In en, this message translates to:
  /// **'Place new order'**
  String get checkoutNew;

  /// No description provided for @checkoutOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time order'**
  String get checkoutOneTime;

  /// No description provided for @checkoutMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk & Dairy'**
  String get checkoutMilk;

  /// No description provided for @checkoutWater.
  ///
  /// In en, this message translates to:
  /// **'Water Can'**
  String get checkoutWater;

  /// No description provided for @checkoutPending.
  ///
  /// In en, this message translates to:
  /// **'Your order may have been received. Retry this saved order to check its result before starting another.'**
  String get checkoutPending;

  /// No description provided for @checkoutRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry saved order'**
  String get checkoutRetry;

  /// No description provided for @checkoutContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get checkoutContinue;

  /// No description provided for @checkoutPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order {number} placed'**
  String checkoutPlaced(String number);

  /// No description provided for @checkoutQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {qty}'**
  String checkoutQuantity(int qty);

  /// No description provided for @checkoutLess.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get checkoutLess;

  /// No description provided for @checkoutMore.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get checkoutMore;

  /// No description provided for @checkoutRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get checkoutRemove;

  /// No description provided for @checkoutRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh delivery choices'**
  String get checkoutRefresh;

  /// No description provided for @checkoutNoAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address to continue.'**
  String get checkoutNoAddress;

  /// No description provided for @checkoutAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get checkoutAddress;

  /// No description provided for @checkoutNoSlots.
  ///
  /// In en, this message translates to:
  /// **'No delivery dates or time slots are available. Contact the vendor or refresh later.'**
  String get checkoutNoSlots;

  /// No description provided for @checkoutDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date (IST)'**
  String get checkoutDate;

  /// No description provided for @checkoutSlot.
  ///
  /// In en, this message translates to:
  /// **'Delivery time slot'**
  String get checkoutSlot;

  /// No description provided for @checkoutCutoff.
  ///
  /// In en, this message translates to:
  /// **'Same-day cutoff: {time} IST'**
  String checkoutCutoff(String time);

  /// No description provided for @checkoutPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment on delivery'**
  String get checkoutPayment;

  /// No description provided for @checkoutCash.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get checkoutCash;

  /// No description provided for @checkoutUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI on delivery'**
  String get checkoutUpi;

  /// No description provided for @checkoutQuote.
  ///
  /// In en, this message translates to:
  /// **'Review bill'**
  String get checkoutQuote;

  /// No description provided for @checkoutSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Item total: {amount}'**
  String checkoutSubtotal(String amount);

  /// No description provided for @checkoutDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery charge: {amount}'**
  String checkoutDelivery(String amount);

  /// No description provided for @checkoutTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String checkoutTotal(String amount);

  /// No description provided for @checkoutFree.
  ///
  /// In en, this message translates to:
  /// **'₹0 (Free)'**
  String get checkoutFree;

  /// No description provided for @checkoutPlace.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get checkoutPlace;

  /// No description provided for @checkoutConfirmPrice.
  ///
  /// In en, this message translates to:
  /// **'Confirm new total and place order'**
  String get checkoutConfirmPrice;

  /// No description provided for @checkoutPriceChanged.
  ///
  /// In en, this message translates to:
  /// **'Prices changed. Review the updated bill and confirm the new total.'**
  String get checkoutPriceChanged;

  /// No description provided for @checkoutMoq.
  ///
  /// In en, this message translates to:
  /// **'Increase the quantity to the product\'s minimum order quantity.'**
  String get checkoutMoq;

  /// No description provided for @checkoutStock.
  ///
  /// In en, this message translates to:
  /// **'This product or quantity is unavailable. Remove it or choose an available quantity.'**
  String get checkoutStock;

  /// No description provided for @checkoutCoverage.
  ///
  /// In en, this message translates to:
  /// **'This vendor does not serve the selected address. Choose another address.'**
  String get checkoutCoverage;

  /// No description provided for @checkoutTiming.
  ///
  /// In en, this message translates to:
  /// **'The delivery date or slot is no longer available. Refresh delivery choices.'**
  String get checkoutTiming;

  /// No description provided for @checkoutUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The vendor cannot deliver on this date or is fully booked. Choose another date.'**
  String get checkoutUnavailable;

  /// No description provided for @checkoutMinimum.
  ///
  /// In en, this message translates to:
  /// **'The item total is below the vendor\'s minimum order value.'**
  String get checkoutMinimum;

  /// No description provided for @checkoutLink.
  ///
  /// In en, this message translates to:
  /// **'Accept this vendor\'s account link before ordering. Your existing records will remain protected.'**
  String get checkoutLink;

  /// No description provided for @checkoutInactive.
  ///
  /// In en, this message translates to:
  /// **'Your customer account with this vendor is inactive. Contact the vendor.'**
  String get checkoutInactive;

  /// No description provided for @discoveryMilkType.
  ///
  /// In en, this message translates to:
  /// **'Milk type: {type}'**
  String discoveryMilkType(String type);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
