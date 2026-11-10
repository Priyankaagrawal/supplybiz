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
