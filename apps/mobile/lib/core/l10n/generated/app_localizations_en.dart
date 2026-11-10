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

  @override
  String get authMobile => 'Mobile number';

  @override
  String get authInvalidMobile =>
      'Enter a valid 10-digit mobile number starting with 6–9.';

  @override
  String get authConsent => 'I accept the Terms and Privacy Policy.';

  @override
  String get authTerms => 'Terms';

  @override
  String get authPrivacy => 'Privacy Policy';

  @override
  String get authSend => 'Send OTP';

  @override
  String get authWhatsapp => 'Continue with WhatsApp';

  @override
  String get authSms => 'Sent via SMS';

  @override
  String get authCode => '6-digit verification code';

  @override
  String get authVerify => 'Verify';

  @override
  String get authResend => 'Resend OTP';

  @override
  String authResendWait(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authChangeNumber => 'Change number';

  @override
  String get authWrongOtp => 'Incorrect code. Please try again.';

  @override
  String get authExpiredOtp =>
      'This code has expired. Please request a new one.';

  @override
  String get authExhaustedOtp =>
      'Too many incorrect attempts. Please request a new code.';

  @override
  String get authDeliveryUnavailable =>
      'OTP delivery is unavailable. Please try again later.';

  @override
  String get authLegalUnavailable =>
      'Terms and Privacy Policy are unavailable. Please try again later.';

  @override
  String get authCustomer => 'I want to buy';

  @override
  String get authVendor => 'I sell / supply';

  @override
  String get authLogout => 'Logout';

  @override
  String get authLogoutAll => 'Logout from all devices';

  @override
  String get authRetry => 'Retry';

  @override
  String get authTrust =>
      'Secure Registration • Quick & Easy Setup • Start Supplying Today';

  @override
  String get updateRequired => 'Update Supply Biz to continue.';

  @override
  String get updateAction => 'Update';

  @override
  String get updateStoreUnavailable =>
      'The store could not be opened. Try again when it is available.';

  @override
  String get configUnavailable =>
      'App configuration is unavailable. Check your connection and try again.';

  @override
  String get onboardingInvalid => 'Enter a valid value.';

  @override
  String get onboardingAccountMismatch => 'Account numbers must match.';

  @override
  String onboardingStep(int step) {
    return 'Step $step of 4';
  }

  @override
  String get onboardingCategory => 'Choose your business category';

  @override
  String get onboardingNoCategories =>
      'No categories are available. Try again later.';

  @override
  String get onboardingBusinessName => 'Business name';

  @override
  String get onboardingGstin => 'GSTIN (optional)';

  @override
  String get onboardingAddress => 'Shop address';

  @override
  String get onboardingCity => 'City';

  @override
  String get onboardingState => 'State';

  @override
  String get onboardingPincode => 'Pincode';

  @override
  String get onboardingLatitude => 'Shop latitude';

  @override
  String get onboardingLongitude => 'Shop longitude';

  @override
  String get onboardingShopPhoto => 'Shop photo';

  @override
  String get onboardingAadhaarFront => 'Masked Aadhaar front';

  @override
  String get onboardingAadhaarBack => 'Masked Aadhaar back';

  @override
  String get onboardingPanPhoto => 'PAN document';

  @override
  String get onboardingPan => 'PAN number';

  @override
  String get onboardingHolder => 'Account holder name';

  @override
  String get onboardingBank => 'Bank name';

  @override
  String get onboardingAccount => 'Account number';

  @override
  String get onboardingConfirmAccount => 'Confirm account number';

  @override
  String get onboardingIfsc => 'IFSC';

  @override
  String get onboardingUpi => 'UPI ID (optional)';

  @override
  String get onboardingSecurityNote =>
      'Used only for verification. Screenshots are blocked on these screens.';

  @override
  String get onboardingMaskGuide =>
      'Hide the first 8 Aadhaar digits everywhere on the document, including any reverse-side copies. Supply an already masked document or use the image masking tool. Do not upload a full Aadhaar number.';

  @override
  String get onboardingMaskedPdf =>
      'PDFs must already be masked. Check every page before choosing this file.';

  @override
  String get onboardingMaskConfirm =>
      'I confirm that all Aadhaar numbers have their first 8 digits hidden.';

  @override
  String get onboardingMaskTool => 'Add a black masking rectangle';

  @override
  String get onboardingMaskX => 'Mask horizontal position';

  @override
  String get onboardingMaskY => 'Mask vertical position';

  @override
  String get onboardingMaskWidth => 'Mask width';

  @override
  String get onboardingMaskHeight => 'Mask height';

  @override
  String get onboardingUseDocument => 'Use masked document';

  @override
  String get onboardingClose => 'Close';

  @override
  String get onboardingFileError =>
      'Choose a valid JPG, PNG or PDF up to 5 MB (images up to 20 megapixels).';

  @override
  String get onboardingSecureError =>
      'Screen protection is unavailable. Retry before entering verification details.';

  @override
  String get onboardingPreviewError =>
      'Unable to open the attachment. Try again.';

  @override
  String get onboardingDocumentsRequired =>
      'Attach all three verification documents.';

  @override
  String get onboardingContinue => 'Save & Continue';

  @override
  String get onboardingSubmit => 'Submit for verification';

  @override
  String get onboardingEditBusiness => 'Edit business details';

  @override
  String get onboardingResubmit => 'Resubmit verification';

  @override
  String get onboardingRefresh => 'Refresh status';

  @override
  String get onboardingVerified => 'Verified by manual review';

  @override
  String get onboardingRejected => 'Verification rejected';

  @override
  String get onboardingReview => 'Awaiting manual review';

  @override
  String get onboardingNotVerified => 'Not verified';

  @override
  String get onboardingHidden =>
      'Your shop is hidden from customer discovery until verification is approved.';

  @override
  String get onboardingManualMethod => 'Verification method: manual review';

  @override
  String get onboardingProviderNotRun => 'Automated provider checks: NOT_RUN';

  @override
  String onboardingMaskedAccount(String last4) {
    return 'Account ending $last4';
  }

  @override
  String onboardingUpload(String label) {
    return 'Choose / replace $label';
  }

  @override
  String onboardingView(String label) {
    return 'View $label';
  }

  @override
  String onboardingRetryUpload(String label) {
    return 'Retry upload: $label';
  }

  @override
  String get areaLocation => 'Shop location';

  @override
  String get areaSaveCoverage => 'Save coverage';

  @override
  String get areaCoverage => 'Delivery coverage';

  @override
  String get areaGps => 'Use current location';

  @override
  String get areaTitle => 'Service area';

  @override
  String get areaBusinessRequired =>
      'Complete business details in onboarding before setting a location.';

  @override
  String get areaGpsError =>
      'Location unavailable or permission denied. Enter coordinates manually or try again.';

  @override
  String get areaPincodes => 'Additional pincodes (separate with commas)';

  @override
  String get areaExplanation =>
      'Coverage includes customers within the radius OR an additional pincode. Leave radius blank for pincodes only. Save shop location separately before changing coverage.';

  @override
  String get areaSaved => 'Saved to server.';

  @override
  String get areaReverification =>
      'Changing verified business details requires re-verification. Your saved details have not changed.';

  @override
  String get areaRadius => 'Radius in km (1–20, optional)';

  @override
  String get areaInvalid =>
      'Use a radius from 1 to 20 and/or unique six-digit Indian pincodes.';

  @override
  String get areaSaveLocation => 'Save shop location';
}
