// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeChooseLocation => 'Choose location';

  @override
  String homeLocation(String area, String city, String pincode) {
    return '$area, $city · $pincode';
  }

  @override
  String get homeLocationHelp =>
      'Use this location to find vendors. Manage delivery addresses separately in Addresses.';

  @override
  String get homeArea => 'Area or address (required)';

  @override
  String get homeUseLocation => 'Use this location';

  @override
  String get homeSavedAddresses => 'Choose a saved address';

  @override
  String get homeSearchTitle => 'Search vendors and products';

  @override
  String get homeSearchHint =>
      'Find vendors by name or by products they carry.';

  @override
  String get homeSearchAction => 'Search';

  @override
  String get homeRecentSearches => 'Recent searches';

  @override
  String get homeSearchEmpty =>
      'No vendors match in this area. Try another search or change your location.';

  @override
  String get homeLocationRequired => 'Choose a location to search for vendors.';

  @override
  String homeDistance(String distance) {
    return '$distance km away';
  }

  @override
  String homeUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get homeRefresh => 'Refresh home';

  @override
  String get homeStale =>
      'Showing the last loaded home. Refresh online for current delivery statuses.';

  @override
  String get homeCategories => 'Supply categories';

  @override
  String get homeNoCategories => 'No supply categories are available yet.';

  @override
  String homeComingSoon(String name) {
    return '$name — Coming soon';
  }

  @override
  String get homeToday => 'Today\'s deliveries';

  @override
  String get homeNoDeliveries =>
      'No deliveries today. Browse the supply categories to find vendors.';

  @override
  String get homeVendor => 'Vendor';

  @override
  String homeOrder(String number) {
    return 'Order $number';
  }

  @override
  String homeProduct(String name, int qty) {
    return '$name × $qty';
  }

  @override
  String get homeMoreDeliveries => 'More deliveries';

  @override
  String get homeMoreVendors => 'More vendors';

  @override
  String get homeStatusNew => 'New';

  @override
  String get homeStatusAccepted => 'Accepted';

  @override
  String get homeStatusPreparing => 'Preparing';

  @override
  String get homeStatusOut => 'Out for delivery';

  @override
  String get homeStatusDelivered => 'Delivered';

  @override
  String get homeStatusRejected => 'Rejected';

  @override
  String get homeStatusCancelled => 'Cancelled';

  @override
  String get homeStatusFailed => 'Failed';

  @override
  String get homeStatusUnknown => 'Status unavailable';

  @override
  String get addressTitle => 'Addresses';

  @override
  String get addressAdd => 'Add address';

  @override
  String get addressEdit => 'Edit address';

  @override
  String get addressSave => 'Save address';

  @override
  String get addressDelete => 'Delete address';

  @override
  String addressDeleteConfirm(String label) {
    return 'Delete $label? If it is your default address, another saved address will become default.';
  }

  @override
  String get addressEmpty =>
      'No saved addresses. Add an address for deliveries.';

  @override
  String get addressDefault => 'Default address';

  @override
  String get addressMakeDefault => 'Use as default address';

  @override
  String get addressLabel => 'Label (required)';

  @override
  String get addressHouse => 'House or flat (required)';

  @override
  String get addressArea => 'Street or area (required)';

  @override
  String get addressLandmark => 'Landmark (optional)';

  @override
  String addressCoordinates(String latitude, String longitude) {
    return 'Latitude $latitude, longitude $longitude';
  }

  @override
  String get addressStale =>
      'Refresh online before changing addresses. Displayed addresses may be out of date.';

  @override
  String get addressPending =>
      'An address request needs confirmation. Retry the saved request before making another change.';

  @override
  String get addressExpired =>
      'The retry window has ended. Refresh and review your addresses, then dismiss the saved request before making another change.';

  @override
  String get addressDismiss => 'Dismiss saved request';

  @override
  String get addressDefaultRequired =>
      'Choose another default address before clearing this default.';

  @override
  String get customersAdd => 'Add customer';

  @override
  String get customersEdit => 'Edit customer';

  @override
  String get customersView => 'View customer';

  @override
  String get customersDetail => 'Customer details';

  @override
  String get customersSave => 'Save customer';

  @override
  String get customersConfirm => 'Confirm';

  @override
  String get customersSaved => 'Customer saved.';

  @override
  String get customersName => 'Name (required)';

  @override
  String get customersMobile => 'Mobile (required)';

  @override
  String get customersEmail => 'Email (optional)';

  @override
  String get customersAddress => 'Address (optional)';

  @override
  String get customersPayment => 'Preferred payment method';

  @override
  String get customersCash => 'Cash';

  @override
  String get customersUpi => 'UPI';

  @override
  String get customersBank => 'Bank transfer';

  @override
  String get customersWallet => 'Wallet';

  @override
  String get customersInvalid => 'Enter a valid value.';

  @override
  String get customersAll => 'All';

  @override
  String get customersActive => 'Active';

  @override
  String get customersInactive => 'Inactive';

  @override
  String get customersSubscribed => 'Subscription';

  @override
  String get customersSearch => 'Search by name or mobile';

  @override
  String get customersFilter => 'Filter customers';

  @override
  String get customersMore => 'Show more customers';

  @override
  String get customersEmpty =>
      'No customers match. Add a customer or change your filters.';

  @override
  String get customersOfflineAccount => 'Offline customer';

  @override
  String get customersLinked => 'Linked app account';

  @override
  String get customersNotFound => 'This customer is not available.';

  @override
  String get customersNoAddress => 'No address added.';

  @override
  String get customersCall => 'Call customer';

  @override
  String get customersDialUnavailable => 'A phone app could not be opened.';

  @override
  String get customersDeactivate => 'Mark inactive';

  @override
  String get customersReactivate => 'Reactivate customer';

  @override
  String customersStatusConfirm(String name) {
    return 'Change the status of $name?';
  }

  @override
  String get customersKeepHistory =>
      'The customer will stop counting toward your limit. Their history will be kept.';

  @override
  String get customersCheckCapacity =>
      'Reactivation counts toward your active customer limit.';

  @override
  String customersCapacity(int count, int limit) {
    return '$count active customers · limit $limit';
  }

  @override
  String get customersDuplicate =>
      'This mobile number is already in your customer list.';

  @override
  String get customersLimitReached =>
      'Your active customer limit has been reached. Mark a customer inactive or contact support about a plan change.';

  @override
  String get customersLinkedMobile =>
      'The mobile number of a linked app account cannot be changed.';

  @override
  String get customersOffline =>
      'Offline — showing saved customers. Changes are unavailable until you refresh online.';

  @override
  String get customersPending =>
      'A saved request needs confirmation. Retry it before making another change.';

  @override
  String get customersRetrySaved => 'Retry saved request';

  @override
  String get customersActivityUnavailable =>
      'Customer activity details are not available yet.';

  @override
  String get customersAddOrder => 'Add order';

  @override
  String get customersOrders => 'Order history';

  @override
  String get customersSubscriptions => 'Current subscription';

  @override
  String get customersPayments => 'Payments';

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

  @override
  String get productsTitle => 'Products';

  @override
  String get productsAdd => 'Add product';

  @override
  String get productsEdit => 'Edit product';

  @override
  String get productsSave => 'Save product';

  @override
  String get productsSearch => 'Search products by name';

  @override
  String get productsFilter => 'Product type filter';

  @override
  String get productsAll => 'All';

  @override
  String get productsMilk => 'Milk';

  @override
  String get productsPaneer => 'Paneer';

  @override
  String get productsCurd => 'Curd';

  @override
  String get productsOther => 'Other';

  @override
  String get productsGhee => 'Ghee';

  @override
  String get productsEmpty =>
      'No products found. Add a product or change your search.';

  @override
  String get productsOffline =>
      'Showing your saved catalog. Refresh online before making changes. Photos may be unavailable offline.';

  @override
  String get productsPending =>
      'A saved request needs confirmation. Retry it before making another change.';

  @override
  String get productsRetryPending => 'Retry saved request';

  @override
  String get productsName => 'Product name';

  @override
  String get productsType => 'Product type';

  @override
  String get productsMilkType => 'Milk type';

  @override
  String get productsCow => 'Cow';

  @override
  String get productsBuffalo => 'Buffalo';

  @override
  String get productsToned => 'Toned';

  @override
  String get productsDoubleToned => 'Double toned';

  @override
  String get productsFullCream => 'Full cream';

  @override
  String get productsUnitValue => 'Pack size (up to 3 decimal places)';

  @override
  String get productsUnit250 => '250 ml';

  @override
  String get productsUnit500 => '500 ml';

  @override
  String get productsUnitLitre => '1 L';

  @override
  String get productsUnitType => 'Pack unit';

  @override
  String get productsSellingPrice => 'Selling price (₹)';

  @override
  String get productsSubscriptionPrice => 'Subscription price (₹, optional)';

  @override
  String get productsStock => 'Stock (packs)';

  @override
  String get productsMoq => 'Minimum order (packs)';

  @override
  String get productsDescription => 'Description (optional)';

  @override
  String get productsActive => 'Active';

  @override
  String get productsInactive => 'Inactive';

  @override
  String get productsDelete => 'Delete product';

  @override
  String get productsDeleteConfirm =>
      'Delete this product? Its stock and sales history will be kept.';

  @override
  String get productsCancel => 'Cancel';

  @override
  String get productsInUse =>
      'This product has active or paused subscriptions. End those subscriptions before deleting it. You can deactivate it instead.';

  @override
  String get productsInsufficient =>
      'Stock cannot be reduced below zero. Refresh and check the quantity.';

  @override
  String get productsAdjust => 'Adjust stock';

  @override
  String get productsDelta => 'Change in packs (for example, -2 or 5)';

  @override
  String get productsReason => 'Reason for adjustment';

  @override
  String get productsApply => 'Apply adjustment';

  @override
  String get productsInvalid =>
      'Check the name, pack size, whole-pack quantities and prices. Subscription price must not exceed selling price.';

  @override
  String get productsPhoto => 'Product photo';

  @override
  String get productsChoosePhoto => 'Choose product photo';

  @override
  String get productsRemovePhoto => 'Remove photo';

  @override
  String get productsPhotoOnly => 'Choose a JPEG or PNG image up to 5 MB.';

  @override
  String get productsPhotoUnavailable => 'Product photo unavailable';

  @override
  String get productsNoTypes =>
      'No product types are configured for your category. Contact support.';

  @override
  String productsStockValue(int quantity) {
    return 'Stock: $quantity packs';
  }

  @override
  String get notificationsReadItem => 'Read notification';

  @override
  String get notificationsNow => 'Just now';

  @override
  String get notificationsUnreadItem => 'Unread notification';

  @override
  String notificationsHours(int count) {
    return '$count hr ago';
  }

  @override
  String get notificationsClearConfirm =>
      'Clear all notifications for this role?';

  @override
  String get notificationsContinue => 'Continue';

  @override
  String notificationsUnread(int count) {
    return '$count unread';
  }

  @override
  String get notificationsPreferences => 'Push preferences';

  @override
  String get notificationsOpenFailed =>
      'Could not open this notification. Refresh the inbox and try again.';

  @override
  String get notificationsPermissionDenied =>
      'Alerts are blocked. You can allow notifications in Android Settings. Your inbox still works.';

  @override
  String get notificationsPermissionAllowed =>
      'Permission allowed. Alerts will be available after device registration succeeds.';

  @override
  String get notificationsSignIn => 'Sign in to view notifications.';

  @override
  String get notificationsPermissionBody =>
      'Enable alerts for orders, payments and account updates? Android will ask for notification permission after you continue. Your inbox works without alerts.';

  @override
  String get notificationsMandatory =>
      'Preferences affect optional push alerts only. Security and KYC updates remain enabled. Inbox items are kept for 90 days.';

  @override
  String get notificationsSystem => 'System';

  @override
  String get notificationsUnavailable =>
      'Push alerts are unavailable in this build. The inbox and preferences still work.';

  @override
  String get notificationsEmpty => 'No notifications in this category.';

  @override
  String get notificationsRetrySaved => 'Retry saved action';

  @override
  String notificationsMinutes(int count) {
    return '$count min ago';
  }

  @override
  String get notificationsDelivery => 'Delivery';

  @override
  String get notificationsOpen => 'Open';

  @override
  String get notificationsEnable => 'Enable push alerts';

  @override
  String get notificationsPayments => 'Payments';

  @override
  String get notificationsVendor => 'Vendor';

  @override
  String get notificationsCustomer => 'Customer';

  @override
  String get notificationsCancel => 'Cancel';

  @override
  String get notificationsAll => 'All';

  @override
  String notificationsSwitchRole(String role) {
    return 'Switch to $role to open this notification?';
  }

  @override
  String get notificationsRefresh => 'Refresh';

  @override
  String get notificationsReadAll => 'Mark all as read';

  @override
  String get notificationsNew => 'You have a new notification.';

  @override
  String notificationsDays(int count) {
    return '$count days ago';
  }

  @override
  String get notificationsClear => 'Clear all notifications';

  @override
  String get discoveryVendors => 'Browse vendors';

  @override
  String get discoveryFavorites => 'Favorites';

  @override
  String get discoverySort => 'Sort vendors';

  @override
  String get discoveryNearby => 'Nearby';

  @override
  String get discoveryPopular => 'Popular';

  @override
  String get discoveryNoFavorites => 'No favorite vendors available here.';

  @override
  String get discoveryOpenVendor => 'View vendor';

  @override
  String get discoveryFavorite => 'Add to favorites';

  @override
  String get discoveryUnfavorite => 'Remove from favorites';

  @override
  String get discoveryAbout => 'About';

  @override
  String discoveryDeliveryCharge(String amount) {
    return 'Delivery charge: $amount';
  }

  @override
  String discoveryMinimumOrder(String amount) {
    return 'Minimum order: $amount';
  }

  @override
  String get discoveryHoursUnavailable => 'Opening hours are unavailable.';

  @override
  String get discoveryHolidays => 'Upcoming holidays';

  @override
  String get discoveryNoHolidays => 'No upcoming holidays listed.';

  @override
  String get discoverySubscriptionInfo =>
      'Subscription prices are shown per pack. Subscription setup will be available separately.';

  @override
  String get discoveryNoProducts => 'No products available.';

  @override
  String get discoveryOpenProduct => 'View product';

  @override
  String discoveryPack(String value, String unit) {
    return '$value $unit per pack';
  }

  @override
  String discoveryMoq(int qty) {
    return 'Minimum quantity: $qty';
  }

  @override
  String get discoveryOutOfStock => 'Out of stock';

  @override
  String discoveryQuantity(int qty) {
    return 'Quantity: $qty';
  }

  @override
  String get discoveryDecrease => 'Decrease quantity';

  @override
  String get discoveryIncrease => 'Increase quantity';

  @override
  String get discoveryAddCart => 'Add to cart';

  @override
  String get discoveryChanged =>
      'Product details changed. Review the updated price and quantity before adding.';

  @override
  String get discoveryReplaceCart =>
      'Your cart contains another vendor. Replace it with this vendor?';

  @override
  String get discoveryAdded => 'Added to cart.';

  @override
  String get discoveryCartError =>
      'Could not add this quantity. Review stock and try again.';

  @override
  String discoveryCart(int count) {
    return 'Cart ($count items)';
  }

  @override
  String get discoveryCartEmpty => 'Your cart is empty.';

  @override
  String get discoveryCartNotice =>
      'Saved locally. Prices and availability will be checked at checkout.';

  @override
  String get discoveryClearCart => 'Clear cart';

  @override
  String get discoveryClearConfirm => 'Remove all items from your cart?';

  @override
  String get discoveryRetryPending =>
      'A favorite update is awaiting confirmation. Retry the saved update before changing another favorite.';

  @override
  String get discoveryRetryExpired =>
      'This saved update is older than 24 hours. Refresh favorites before making another change.';

  @override
  String get discoveryDismiss => 'Refresh favorites';

  @override
  String get discoveryDismissConfirm =>
      'Refresh favorites to check the current state and clear this expired update?';

  @override
  String get discoveryImageUnavailable => 'Image unavailable';

  @override
  String get discoveryImage => 'Vendor or product image';

  @override
  String get discoverySubscription => 'Subscription';

  @override
  String get ordersFilter => 'Order status';

  @override
  String get ordersSearch => 'Search customer name or order number';

  @override
  String get ordersDate => 'Delivery date (YYYY-MM-DD, IST)';

  @override
  String get ordersInvalidDate => 'Enter a valid date as YYYY-MM-DD.';

  @override
  String get ordersAllDates => 'All delivery dates';

  @override
  String get ordersEmpty => 'No orders found.';

  @override
  String get ordersOpen => 'View order';

  @override
  String get ordersMore => 'Load more orders';

  @override
  String get ordersDetails => 'Order details';

  @override
  String get ordersCached =>
      'Showing saved order data. Refresh online before changing an order.';

  @override
  String get ordersPending =>
      'An order update is awaiting confirmation. Retry the saved update before making another change.';

  @override
  String get ordersRetrySaved => 'Retry saved order update';

  @override
  String get ordersNoLongerAvailable =>
      'Order no longer available for that action. The latest order has been refreshed.';

  @override
  String get ordersItems => 'Order items';

  @override
  String ordersDiscount(String amount) {
    return 'Discount: $amount';
  }

  @override
  String get ordersPaid => 'Paid';

  @override
  String get ordersUnpaid => 'Unpaid';

  @override
  String get ordersApp => 'App order';

  @override
  String get ordersVendor => 'Vendor-created order';

  @override
  String get ordersTimeline => 'Status timeline';

  @override
  String get ordersIst => 'IST';

  @override
  String get ordersAccept => 'Accept order';

  @override
  String get ordersReject => 'Reject order';

  @override
  String get ordersPacked => 'Mark packed';

  @override
  String get ordersStartDelivery => 'Start delivery';

  @override
  String get ordersReason => 'Rejection reason';

  @override
  String get ordersReasonHelp => 'Explain the reason in 5–200 characters.';

  @override
  String get ordersCustomerUnavailable => 'Customer not available';

  @override
  String get ordersOutOfStock => 'Product out of stock';

  @override
  String get ordersNotServiceable => 'Area not serviceable';

  @override
  String get ordersCustomerRequest => 'Customer requested to cancel';

  @override
  String get ordersOther => 'Other';

  @override
  String get checkoutTitle => 'Cart and checkout';

  @override
  String get checkoutNew => 'Place new order';

  @override
  String get checkoutOneTime => 'One-time order';

  @override
  String get checkoutMilk => 'Milk & Dairy';

  @override
  String get checkoutWater => 'Water Can';

  @override
  String get checkoutPending =>
      'Your order may have been received. Retry this saved order to check its result before starting another.';

  @override
  String get checkoutRetry => 'Retry saved order';

  @override
  String get checkoutContinue => 'Continue shopping';

  @override
  String checkoutPlaced(String number) {
    return 'Order $number placed';
  }

  @override
  String checkoutQuantity(int qty) {
    return 'Quantity: $qty';
  }

  @override
  String get checkoutLess => 'Decrease quantity';

  @override
  String get checkoutMore => 'Increase quantity';

  @override
  String get checkoutRemove => 'Remove item';

  @override
  String get checkoutRefresh => 'Refresh delivery choices';

  @override
  String get checkoutNoAddress => 'Add a delivery address to continue.';

  @override
  String get checkoutAddress => 'Delivery address';

  @override
  String get checkoutNoSlots =>
      'No delivery dates or time slots are available. Contact the vendor or refresh later.';

  @override
  String get checkoutDate => 'Delivery date (IST)';

  @override
  String get checkoutSlot => 'Delivery time slot';

  @override
  String checkoutCutoff(String time) {
    return 'Same-day cutoff: $time IST';
  }

  @override
  String get checkoutPayment => 'Payment on delivery';

  @override
  String get checkoutCash => 'Cash on delivery';

  @override
  String get checkoutUpi => 'UPI on delivery';

  @override
  String get checkoutQuote => 'Review bill';

  @override
  String checkoutSubtotal(String amount) {
    return 'Item total: $amount';
  }

  @override
  String checkoutDelivery(String amount) {
    return 'Delivery charge: $amount';
  }

  @override
  String checkoutTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get checkoutFree => '₹0 (Free)';

  @override
  String get checkoutPlace => 'Place Order';

  @override
  String get checkoutConfirmPrice => 'Confirm new total and place order';

  @override
  String get checkoutPriceChanged =>
      'Prices changed. Review the updated bill and confirm the new total.';

  @override
  String get checkoutMoq =>
      'Increase the quantity to the product\'s minimum order quantity.';

  @override
  String get checkoutStock =>
      'This product or quantity is unavailable. Remove it or choose an available quantity.';

  @override
  String get checkoutCoverage =>
      'This vendor does not serve the selected address. Choose another address.';

  @override
  String get checkoutTiming =>
      'The delivery date or slot is no longer available. Refresh delivery choices.';

  @override
  String get checkoutUnavailable =>
      'The vendor cannot deliver on this date or is fully booked. Choose another date.';

  @override
  String get checkoutMinimum =>
      'The item total is below the vendor\'s minimum order value.';

  @override
  String get checkoutLink =>
      'Accept this vendor\'s account link before ordering. Your existing records will remain protected.';

  @override
  String get checkoutInactive =>
      'Your customer account with this vendor is inactive. Contact the vendor.';

  @override
  String discoveryMilkType(String type) {
    return 'Milk type: $type';
  }
}
