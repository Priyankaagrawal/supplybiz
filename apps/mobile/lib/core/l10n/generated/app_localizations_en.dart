// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get khataTitle => 'Customer Khata';

  @override
  String get khataPayments => 'Payments & collection';

  @override
  String get khataReceivable => 'Total receivable';

  @override
  String get khataMonthReceived =>
      'Khata collections this month, net of corrections';

  @override
  String get khataSettled => 'Paid / settled';

  @override
  String get khataDebit => 'Debits';

  @override
  String get khataCredit => 'Credits';

  @override
  String get khataPaid => 'Payments received, net';

  @override
  String get khataDue => 'Current due / advance';

  @override
  String get khataArchived => 'Archived account · history only';

  @override
  String get khataEmpty => 'No customer accounts yet.';

  @override
  String get khataRecord => 'Record payment';

  @override
  String get khataOpening => 'Opening balance';

  @override
  String get khataReverse => 'Reverse entry';

  @override
  String get khataReversal => 'Reversal / correction';

  @override
  String get khataOriginalRetained =>
      'The original entry stays in the ledger. This correction appends an opposite entry and an audit record.';

  @override
  String get khataNoAllocation =>
      'Payments are recorded against this account. Unallocated payments do not change individual order payment statuses.';

  @override
  String get khataPending =>
      'An uncertain financial change is saved privately. Retry the same change before creating another; no automatic resend occurs.';

  @override
  String get khataLocked =>
      'New opening balances and reversals need an active plan with Khata. History and eligible payment/claim settlement remain available after expiry.';

  @override
  String get khataAlreadyReversed =>
      'This entry already has a reversal. Refresh to review the ledger.';

  @override
  String get khataChanged =>
      'This claim or account changed. Refresh and review before acting again.';

  @override
  String get khataClaimExceeds =>
      'The claim exceeds the current amount due. Refresh and review the claim.';

  @override
  String get khataShowMonth => 'Show month';

  @override
  String get khataCollections => 'Recorded collections';

  @override
  String khataRecordedAt(String time) {
    return 'Recorded $time IST';
  }

  @override
  String get khataCollectionsEmpty => 'No collections recorded for this month.';

  @override
  String get khataNetInfo =>
      'Customer account payments, paid customer sales and confirmed claims are shown once. Signed corrections adjust their net total; opening credits are not payments.';

  @override
  String get khataClaims => 'Customer payment claims';

  @override
  String get khataClaimPending => 'Pending';

  @override
  String get khataClaimConfirmed => 'Confirmed';

  @override
  String get khataClaimRejected => 'Rejected';

  @override
  String get khataClaimInfo =>
      'This is the customer’s statement, not verified payment. Confirm only after checking you received it. Confirmation records one credit; rejection requires a reason.';

  @override
  String get khataConfirmClaim => 'Confirm payment claim';

  @override
  String get khataRejectClaim => 'Reject payment claim';

  @override
  String get khataAmount => 'Amount (₹)';

  @override
  String get khataInvalidAmount =>
      'Enter a positive amount with up to two decimal places within the supported limit.';

  @override
  String get khataEntryType => 'Opening balance type';

  @override
  String get khataNote => 'Note';

  @override
  String get khataReceivedOn => 'Received date';

  @override
  String get khataBank => 'Bank';

  @override
  String get khataWallet => 'Wallet (external record)';

  @override
  String get salesTitle => 'Quick Sale';

  @override
  String get salesWalkin => 'Sale on POS';

  @override
  String get salesCustomer => 'Customer Sale';

  @override
  String get salesSearch => 'Search products';

  @override
  String get salesAdd => 'Add product';

  @override
  String get salesQty => 'Quantity (whole packs)';

  @override
  String get salesRate => 'Rate per pack (₹)';

  @override
  String get salesPaid => 'Paid amount';

  @override
  String get salesBalance => 'Balance';

  @override
  String get salesTotal => 'Total amount';

  @override
  String get salesFullPaid => 'Paid in full';

  @override
  String get salesComplete => 'Complete Sale';

  @override
  String get salesNew => 'New sale';

  @override
  String get salesReceipt => 'View receipt';

  @override
  String get salesReceipts => 'Recent confirmed receipts on this device';

  @override
  String get salesWalkinPaid =>
      'Walk-in sales must be paid in full. Select a customer to record an unpaid balance.';

  @override
  String get salesInvalid =>
      'Check whole-pack quantities, available stock and amounts (up to two decimal places). Paid cannot exceed total.';

  @override
  String get salesExternal =>
      'Record a payment made directly to you. This does not transfer money or verify a UPI payment.';

  @override
  String get salesCached =>
      'Saved catalog. Prices, products, customer eligibility, plan and stock are checked when the sale syncs.';

  @override
  String get salesLocked =>
      'Quick Sale needs an active eligible plan. Contact support, then explicitly retry the saved sale.';

  @override
  String get salesCustomerMissing =>
      'The selected customer is no longer available. Refresh and review the sale.';

  @override
  String get salesQueue => 'Sale sync queue';

  @override
  String get salesQueueEmpty => 'No pending sales.';

  @override
  String get salesQueueInfo =>
      'Pending sales reserve local stock. Only a server receipt confirms a completed sale. Uncertain sends keep the same reference when retried.';

  @override
  String get salesRetry => 'Retry saved sales';

  @override
  String get salesPending => 'Saved locally · Pending sync';

  @override
  String get salesRejected => 'Not completed · Review and enter a new sale';

  @override
  String get salesNeedsRetry => 'Needs explicit retry';

  @override
  String get salesDiscard => 'Discard unsent or rejected sale';

  @override
  String get salesDiscardInfo =>
      'Remove this local record. A sale with an uncertain server result cannot be discarded.';

  @override
  String salesAvailable(int count) {
    return 'Available after pending sales: $count';
  }

  @override
  String salesItemCount(int count) {
    return 'Total packs: $count';
  }

  @override
  String salesConfirmed(String number) {
    return 'Sale confirmed: $number';
  }

  @override
  String salesRemove(String name) {
    return 'Remove $name from sale';
  }

  @override
  String get availabilityTitle => 'Availability & holidays';

  @override
  String get availabilityAccepting => 'Accepting deliveries today';

  @override
  String get availabilityAcceptingInfo =>
      'Turning this off stops new one-time orders for today. Existing orders and subscriptions remain.';

  @override
  String get availabilityPause => 'Pause deliveries';

  @override
  String get availabilityResume => 'Resume deliveries';

  @override
  String get availabilityPaused => 'Deliveries paused';

  @override
  String get availabilityRunning => 'Deliveries running';

  @override
  String get availabilityPauseInfo =>
      'Pause deliveries until you choose Resume. Eligible orders from today onward will be cancelled. Out-for-delivery and completed orders remain.';

  @override
  String get availabilityResumeInfo =>
      'Restore future delivery eligibility. Previously cancelled orders are not restored.';

  @override
  String get availabilityMarkHoliday => 'Mark holiday';

  @override
  String get availabilityDelete => 'Delete holiday';

  @override
  String get availabilityDate => 'Holiday date';

  @override
  String get availabilityFutureOnly => 'Only a future holiday can be deleted.';

  @override
  String get availabilityExists =>
      'A holiday already exists on this date. Refresh to view it.';

  @override
  String get availabilityConflict =>
      'Settings changed. Refresh and review before trying again.';

  @override
  String get availabilitySaved => 'Change saved.';

  @override
  String get availabilityPlanLocked =>
      'Enabling deliveries or deleting holidays requires an active plan. History and reducing controls remain available. Contact support about a plan change.';

  @override
  String get availabilityImpactInfo =>
      'This is a preview. The affected count is checked again when saving. Eligible customers will be notified; no refund or payment reversal is recorded.';

  @override
  String availabilityImpact(int count) {
    return '$count existing orders will be cancelled.';
  }

  @override
  String availabilityCancelled(int count) {
    return 'Saved. $count orders cancelled.';
  }

  @override
  String availabilityBusinessDate(String date) {
    return 'Today: $date (IST)';
  }

  @override
  String availabilityLegacyEnd(String time) {
    return 'Existing pause ends at $time IST.';
  }

  @override
  String get customerSubPlans => 'Subscription plans';

  @override
  String get customerSubMine => 'My subscriptions';

  @override
  String get customerSubMore => 'Load more';

  @override
  String get customerSubCustom => 'Custom plan';

  @override
  String get customerSubPopular => 'Most popular';

  @override
  String get customerSubFree => 'Free delivery';

  @override
  String get customerSubFeatures =>
      'Pause or skip anytime · Monthly billing · Manage from app';

  @override
  String get customerSubAddress => 'Delivery address';

  @override
  String get customerSubConfirm => 'Confirm subscription';

  @override
  String get customerSubCashOnly =>
      'The vendor has not set a payment UPI ID. Cash is the only available option.';

  @override
  String get customerSubStatement => 'Monthly statement';

  @override
  String get customerSubMonth => 'Month (YYYY-MM)';

  @override
  String get customerSubDelivered => 'Delivered subscription orders';

  @override
  String get customerSubLedger =>
      'Shared vendor account: payments and balances include all purchases. Unallocated payments are not assigned to this subscription.';

  @override
  String get customerSubOpening => 'Opening balance';

  @override
  String get customerSubClosing => 'Closing balance';

  @override
  String get customerSubPaid => 'Payments recorded this month';

  @override
  String get customerSubCurrent => 'Current vendor balance';

  @override
  String get customerSubAmount => 'Delivered amount';

  @override
  String get customerSubQuantity => 'Delivered packs';

  @override
  String get customerSubCutoffError =>
      'That date is frozen by the 21:00 IST cutoff. Refresh and choose the next eligible delivery date.';

  @override
  String get customerSubLink =>
      'Accept the vendor’s customer-link request on Home before subscribing.';

  @override
  String get customerSubEmptyStatement =>
      'No delivered orders for this subscription in this month.';

  @override
  String get subTitle => 'Subscriptions';

  @override
  String get subSettings => 'Subscription settings';

  @override
  String get subCreate => 'Create subscription';

  @override
  String get subActive => 'Active';

  @override
  String get subPaused => 'Paused';

  @override
  String get subPending => 'Pending approval';

  @override
  String get subCancelled => 'Cancelled';

  @override
  String get subRejected => 'Rejected';

  @override
  String get subCompleted => 'Completed';

  @override
  String get subApprove => 'Approve';

  @override
  String get subReject => 'Reject';

  @override
  String get subPause => 'Pause';

  @override
  String get subResume => 'Resume';

  @override
  String get subSkip => 'Skip a date';

  @override
  String get subCancel => 'Cancel subscription';

  @override
  String get subSave => 'Save';

  @override
  String get subMon => 'Mon';

  @override
  String get subTue => 'Tue';

  @override
  String get subWed => 'Wed';

  @override
  String get subThu => 'Thu';

  @override
  String get subFri => 'Fri';

  @override
  String get subSat => 'Sat';

  @override
  String get subSun => 'Sun';

  @override
  String get subDailyDays => 'Daily';

  @override
  String get subEmpty => 'No subscriptions match your selection.';

  @override
  String get subOffline => 'Saved data. Refresh online before making changes.';

  @override
  String get subSaved =>
      'A saved change needs acknowledgement. Retry the same change before making another.';

  @override
  String get subRetry => 'Retry saved change';

  @override
  String get subReviewExpired => 'Reload and review expired settings change';

  @override
  String get subPlanLocked =>
      'Creating, editing and resuming subscriptions requires an active STANDARD or higher plan. Contact support about a plan change. History and reducing controls remain available.';

  @override
  String get subBusinessGuidance =>
      'Enabling auto-accept requires BUSINESS or higher. Contact support about a plan change.';

  @override
  String get subAutoAccept => 'Automatically accept subscription orders';

  @override
  String get subAutoEffective =>
      'Auto-accept is effective for the current plan.';

  @override
  String get subAutoInactive =>
      'Auto-accept is not effective for the current configuration and plan.';

  @override
  String get subAvailable => 'Subscription delivery available';

  @override
  String get subPauseAll => 'Pause all subscriptions';

  @override
  String get subCustomer => 'Customer';

  @override
  String get subProduct => 'Product and price per pack';

  @override
  String get subQty => 'Whole packs per delivery';

  @override
  String get subLess => 'Decrease packs per delivery';

  @override
  String get subMore => 'Increase packs per delivery';

  @override
  String get subStart => 'Start date (YYYY-MM-DD)';

  @override
  String get subEnd => 'End date, optional (YYYY-MM-DD)';

  @override
  String get subFrom => 'Delivery date (YYYY-MM-DD)';

  @override
  String get subSlot => 'Configured delivery slot';

  @override
  String get subPayment => 'Payment preference';

  @override
  String get subReason => 'Reason';

  @override
  String get subNoEnd => 'No end date';

  @override
  String get subInvalid =>
      'Check the required selection, whole-pack quantity, days and date or time format.';

  @override
  String get subCutoff =>
      'Customer changes close at 21:00 IST before delivery. Changes after cutoff apply from the next eligible date shown by the server. Existing generated orders remain; use Skip to cancel an eligible dated order.';

  @override
  String get subCancelInfo =>
      'Stop future subscription deliveries. Existing generated orders are retained.';

  @override
  String get subPostpaid =>
      'Monthly amounts are estimates for the selected start month. Postpaid Khata is billed only when an order is delivered; no payment is taken during setup.';

  @override
  String get subConfirmSettings => 'Confirm subscription setting change';

  @override
  String get subSettingsEffect =>
      'This changes future generation eligibility. Individual subscriptions and existing orders are retained.';

  @override
  String get subLimitsInfo =>
      'Limits are shared with other orders. Leave a limit blank for unlimited; clear both times to remove the delivery window. Times are IST; overnight windows are allowed.';

  @override
  String get subOrderCap => 'Daily order limit, optional';

  @override
  String get subMilkCap =>
      'Daily milk capacity in litres, optional (up to 3 decimal places)';

  @override
  String get subWindowStart => 'Delivery window start (HH:mm IST)';

  @override
  String get subWindowEnd => 'Delivery window end (HH:mm IST)';

  @override
  String subMoney(String amount) {
    return '₹$amount';
  }

  @override
  String subDaily(String amount) {
    return 'Per delivery: $amount';
  }

  @override
  String subMonthly(String amount, String month) {
    return 'Estimated $month: $amount';
  }

  @override
  String subEffective(String date) {
    return 'Change recorded, effective from $date.';
  }

  @override
  String subQuantityValue(int qty, String slot) {
    return '$qty packs · $slot';
  }

  @override
  String subDates(String start, String end) {
    return '$start to $end';
  }

  @override
  String subPausedDates(String start, String end) {
    return 'Pause: $start to $end';
  }

  @override
  String subSkippedDate(String date) {
    return 'Skipped: $date';
  }

  @override
  String subSummary(
      int total, int active, int paused, int pending, int customers) {
    return 'Subscriptions: $total · Active: $active · Paused: $paused · Pending approval: $pending · Customers: $customers';
  }

  @override
  String get deliveryTitle => 'Deliveries';

  @override
  String get deliveryQueue => 'Sync queue';

  @override
  String get deliveryCached =>
      'Cached deliveries. Updates stay pending until the server confirms them.';

  @override
  String get deliveryPending => 'Pending';

  @override
  String get deliveryPendingSync => 'Pending sync';

  @override
  String get deliveryEmpty => 'No deliveries for this date';

  @override
  String get deliveryQueueEmpty => 'No queued delivery updates';

  @override
  String get deliveryQueueHelp =>
      'Updates sync automatically when connected, including Android background sync when allowed by your device. Open the app to check progress. Uncertain updates must be retried with their saved key.';

  @override
  String get deliveryRetry => 'Retry saved delivery updates';

  @override
  String get deliveryRejected => 'Update rejected';

  @override
  String get deliveryRetryNeeded =>
      'Automatic retries stopped. Retry when the connection or access is restored.';

  @override
  String get deliveryRollback =>
      'The pending change was rolled back. Refresh deliveries, discard this rejected update, then check the current status before trying again.';

  @override
  String get deliveryDiscard => 'Discard update';

  @override
  String get deliveryDiscardConfirm =>
      'Discard this update and its unsent dependent updates?';

  @override
  String get deliveryCancel => 'Cancel';

  @override
  String get deliveryDelivered => 'Mark delivered';

  @override
  String get deliveryFailed => 'Mark failed';

  @override
  String get deliveryReason => 'Failure reason';

  @override
  String get deliveryReasonRequired => 'Enter a failure reason.';

  @override
  String get deliveryCollected => 'Payment collected?';

  @override
  String get deliveryMethod => 'Payment method';

  @override
  String get deliveryAmount => 'Amount collected (₹)';

  @override
  String get deliveryAmountInvalid =>
      'Enter a valid amount greater than zero with at most two decimal places.';

  @override
  String get customerOrdersOngoing => 'Ongoing';

  @override
  String get customerOrdersCallVendor => 'Call vendor';

  @override
  String get customerOrdersCancel => 'Cancel order';

  @override
  String get customerOrdersCancelConfirm =>
      'Cancel this new order? There is no cancellation fee.';

  @override
  String get customerOrdersReorder => 'Reorder';

  @override
  String get customerOrdersReview => 'Review current prices and availability';

  @override
  String get customerOrdersAdd => 'Add available items to cart';

  @override
  String get customerOrdersUnavailable => 'Unavailable items';

  @override
  String get customerOrdersNoStock => 'Not enough stock for the saved quantity';

  @override
  String get customerOrdersMoq =>
      'The saved quantity is below the current minimum';

  @override
  String get customerOrdersRemoved => 'Product is no longer available';

  @override
  String get customerOrdersConfirmed => 'Confirmed';

  @override
  String get customerOrdersPacked => 'Packed';

  @override
  String get customerOrdersNotYet => 'Not reached';

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
  String get linkTitle => 'Link vendor accounts';

  @override
  String get linkMore => 'Show more account links';

  @override
  String get linkAccept => 'Link account';

  @override
  String get linkDecline => 'Decline link';

  @override
  String linkConsent(String name) {
    return 'Link your account with $name? This connects the vendor\'s existing customer records to your signed-in account.';
  }

  @override
  String linkDeclineConfirm(String name) {
    return 'Decline the link from $name? This request will be dismissed and its records will stay unlinked.';
  }

  @override
  String get linkAccepted => 'Account linked.';

  @override
  String get linkDeclined => 'Link declined.';

  @override
  String get linkEmpty => 'No vendor accounts waiting to be linked.';

  @override
  String get linkRefresh => 'Refresh account links';

  @override
  String get linkPendingAccept =>
      'Your link request is awaiting confirmation. Retry the saved acceptance to check its result.';

  @override
  String get linkPendingDecline =>
      'Your decline is awaiting confirmation. Retry the saved decision to check its result.';

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

  @override
  String get customerKhataPayable => 'Payable';

  @override
  String get customerKhataNet => 'Net balance';

  @override
  String get customerKhataVendors => 'Vendors';

  @override
  String get customerKhataPersonal => 'Customers (personal)';

  @override
  String get customerKhataAdd => 'Add personal contact';

  @override
  String get customerKhataEdit => 'Edit contact';

  @override
  String get customerKhataDelete => 'Delete contact';

  @override
  String get customerKhataDeleteConfirm =>
      'Delete this personal contact and its personal entries?';

  @override
  String get customerKhataName => 'Contact name';

  @override
  String get customerKhataMobile => 'Mobile (optional)';

  @override
  String get customerKhataGave => 'Gave';

  @override
  String get customerKhataGot => 'Got';

  @override
  String get customerKhataAddEntry => 'Add personal entry';

  @override
  String get customerKhataEditEntry => 'Edit personal entry';

  @override
  String get customerKhataDeleteEntry => 'Delete entry';

  @override
  String get customerKhataDeleteEntryConfirm => 'Delete this personal entry?';

  @override
  String get customerKhataBalance => 'Balance';

  @override
  String get customerKhataSettle => 'Settle dues';

  @override
  String get customerKhataCashOnly =>
      'This vendor has no published payment UPI ID. Only cash is available.';

  @override
  String get customerKhataCash => 'I paid cash - submit claim';

  @override
  String get customerKhataUpi => 'Open UPI app';

  @override
  String get customerKhataPaid => 'I\'ve paid';

  @override
  String get customerKhataNotPaid => 'I did not pay - discard draft';

  @override
  String get customerKhataReview =>
      'Did you pay? Submit only if you actually paid. Your claim stays pending until the vendor confirms it.';

  @override
  String get customerKhataFallback =>
      'No UPI app opened. Use this payment QR or copy the UPI ID to pay from another device.';

  @override
  String get customerKhataQr => 'Payment QR code';

  @override
  String get customerKhataCopy => 'Copy UPI ID';

  @override
  String get customerKhataCopied => 'UPI ID copied';

  @override
  String get customerKhataPaymentDetails => 'Payee and payment details';

  @override
  String get customerKhataAccount => 'Billing account';

  @override
  String get customerKhataDueLimit => 'Claim limit';

  @override
  String get customerKhataInvalid =>
      'Enter a valid name, mobile, date and positive amount as applicable. The amount must not exceed the current due or claim limit.';

  @override
  String get customerKhataChanged =>
      'Payment details or dues changed. Refresh and review before paying.';

  @override
  String get customerKhataSaved =>
      'Saved. Payment claims remain pending until vendor confirmation.';

  @override
  String get customerKhataSource => 'Source';

  @override
  String get customerKhataUnallocated =>
      'No source payment allocation recorded';

  @override
  String get customerKhataDirection => 'Direction';

  @override
  String get customerKhataMonthTotal => 'Month payable';

  @override
  String get customerKhataMonthPaid => 'Month paid';

  @override
  String get customerKhataNoDue => 'No eligible outstanding due.';

  @override
  String get customerKhataPendingReview =>
      'A payment draft is saved. Review it before starting another payment.';

  @override
  String get customerKhataConfirmCash =>
      'Confirm that you already paid this amount in cash. This submits a pending claim for vendor review.';

  @override
  String get customerKhataApplyMonth => 'Apply month';

  @override
  String get customerKhataInvalidMonth => 'Enter a valid month as YYYY-MM.';

  @override
  String get customerKhataConfirm => 'Confirm';

  @override
  String get customerKhataMethodCash => 'Cash';

  @override
  String get customerKhataMethodUpi => 'UPI';

  @override
  String get dashShopPhoto => 'Shop photo';

  @override
  String get dashShopMissing => 'Your shop';

  @override
  String get dashCityMissing => 'City not set';

  @override
  String dashSelectedDate(String date) {
    return 'Selected IST date: $date';
  }

  @override
  String get dashApplyDate => 'Apply date';

  @override
  String get dashToday => 'Today';

  @override
  String get dashOrders => 'Orders for date';

  @override
  String get dashPending => 'Pending orders';

  @override
  String get dashCompleted => 'Completed orders';

  @override
  String get dashSales => 'Recorded sales for date';

  @override
  String get dashLifetime => 'Lifetime recorded sales';

  @override
  String get dashMilk => 'Milk stock';

  @override
  String get dashCustomers => 'Active customers';

  @override
  String dashLitres(String value) {
    return '$value L';
  }

  @override
  String get dashReports => 'Reports';

  @override
  String get dashReportsSoon => 'Reports available soon';

  @override
  String get dashScheduledInfo =>
      'Order counts use the scheduled delivery date. Pending includes new, accepted, preparing and out-for-delivery orders.';

  @override
  String get dashGrossInfo =>
      'Sales include delivered orders and Quick Sales, including delivery charges. They represent recorded sales, not payments received or profit.';

  @override
  String get dashCurrentInfo =>
      'Milk stock and active customers show the current state, regardless of selected date.';

  @override
  String dashUnknownMilk(int count) {
    return '$count stocked milk products have units that cannot be converted to litres. Shown volume is incomplete.';
  }

  @override
  String get dashActions => 'Quick actions';

  @override
  String get dashNoCache =>
      'No dashboard data saved for this date. Connect and refresh.';

  @override
  String dashUpdated(String time) {
    return 'Last updated $time IST';
  }

  @override
  String get dashOffline =>
      'Showing saved dashboard data. Connect and refresh for current values.';

  @override
  String get dashCacheUnavailable =>
      'Could not save the dashboard for offline use.';

  @override
  String get dashVerification =>
      'Verification is incomplete. Your shop is hidden from customer discovery until verified.';

  @override
  String get dashPlanUnavailable =>
      'Plan details are unavailable. Refresh to check your current access.';

  @override
  String get dashPlanExpired =>
      'Your plan has expired. History and eligible settlement remain available.';

  @override
  String get dashPlanScheduled =>
      'Your plan is scheduled to start later. Paid features require an active assignment.';

  @override
  String get dashPlanUnassigned =>
      'No plan is assigned. Setup allowance does not unlock paid features.';

  @override
  String get dashPlanSupport =>
      'Contact support for plan assignment or renewal.';

  @override
  String get dashAvailableSoon => 'Available soon';

  @override
  String get dashPlans => 'Plans';

  @override
  String get dashVendorSettings => 'Vendor settings';

  @override
  String get dashHelp => 'Help and FAQ';

  @override
  String get dashAccountSettings => 'Account and security';

  @override
  String get dashSubscriptions => 'Subscriptions';

  @override
  String get dashDeliveries => 'Deliveries';

  @override
  String get dashActiveProducts => 'Showing active products';

  @override
  String get plansView => 'View plans';

  @override
  String get plansCurrent => 'Current assignment';

  @override
  String get plansCatalog => 'Available plan tiers';

  @override
  String get plansSupport =>
      'Contact support to request a plan assignment, extension or change. Support will arrange an authorized admin update. Catalog prices are for reference.';

  @override
  String get plansNoTrial =>
      'There is no automatic free trial or grace period. Plan access is checked by the server.';

  @override
  String get plansActive => 'Active';

  @override
  String get plansUnassigned => 'Unassigned';

  @override
  String get plansScheduled => 'Scheduled';

  @override
  String get plansExpired => 'Expired';

  @override
  String get plansUnavailable => 'Assignment unavailable';

  @override
  String plansCapacity(int count, int limit) {
    return 'Active customers: $count / $limit';
  }

  @override
  String plansSetup(int limit) {
    return 'Setup allows up to $limit active customers without assigning a plan. This does not unlock paid features or customer discovery.';
  }

  @override
  String plansStarts(String time) {
    return 'Starts: $time IST';
  }

  @override
  String plansEnds(String time) {
    return 'Access ends: $time IST';
  }

  @override
  String get plansAtLimit =>
      'The active customer limit has been reached or exceeded. Additions and reactivations are blocked until below the limit.';

  @override
  String get plansGrowthBlocked =>
      'Customer additions and reactivations are currently blocked. Refresh or contact support.';

  @override
  String get plansRetained =>
      'Your existing customers and history are retained. Downgrading does not automatically delete or deactivate customers; permitted existing-customer business continues under the assigned tier.';

  @override
  String get plansExpiryRules =>
      'After expiry, history, payment recording, claim decisions and normally permitted completion or cancellation of existing orders remain. New orders, Quick Sales, subscriptions, generation and customer additions or reactivations are blocked until renewal.';

  @override
  String get plansAssignedFeatures => 'Paid features in the current assignment';

  @override
  String get plansIncluded => 'Included';

  @override
  String get plansLocked => 'Not available in this assignment';

  @override
  String get plansFeatureNotice =>
      'Catalog features describe each tier. The server controls current access; saved information cannot grant features. Expiry exceptions for existing records and eligible settlement still apply.';

  @override
  String get plansBasicReports => 'Basic report summaries';

  @override
  String get plansOrders => 'Basic order management';

  @override
  String get plansDelivery => 'Delivery management and holidays';

  @override
  String get plansAutoAccept => 'Automatic subscription approval';

  @override
  String get plansStock => 'Stock management';

  @override
  String get plansStockAlerts => 'Low-stock alerts';

  @override
  String get plansAdvancedReports => 'Daily/product reports and CSV export';

  @override
  String get plansAdditionalFeature => 'Additional catalog feature';

  @override
  String get plansSavedCurrent =>
      'Showing saved assignment information. Refresh for current status, limits and access.';

  @override
  String get plansSavedCatalog =>
      'Showing saved catalog information. Refresh for current prices and features.';

  @override
  String get plansCacheUnavailable =>
      'Could not save plan information for offline viewing.';

  @override
  String get plansCurrentMissing =>
      'Current assignment information is unavailable. Connect and refresh.';

  @override
  String get plansEmpty =>
      'No active catalog plans are available. Contact support.';

  @override
  String plansCatalogLimit(int limit) {
    return 'Active customer limit: $limit';
  }

  @override
  String get plansPriceUnavailable =>
      'Reference price unavailable. Contact support.';

  @override
  String get plansMonthly => 'Monthly';

  @override
  String get plansHalfYearly => 'Half-yearly';

  @override
  String get plansYearly => 'Yearly';

  @override
  String plansCatalogPrice(String duration, String price) {
    return '$duration: $price';
  }

  @override
  String get reportsOffline =>
      'Offline: showing a previously fetched summary. Refresh before exporting.';

  @override
  String get reportsRangeHelp =>
      'Reports use inclusive IST dates, up to 366 days. Weekly and monthly filters end today.';

  @override
  String get reportsWeek => 'This week';

  @override
  String get reportsMonth => 'This month';

  @override
  String get reportsFrom => 'From (YYYY-MM-DD)';

  @override
  String get reportsTo => 'To (YYYY-MM-DD)';

  @override
  String get reportsInvalidRange =>
      'Enter valid dates in order, covering at most 366 days.';

  @override
  String reportsSelected(String from, String to) {
    return 'Report: $from to $to';
  }

  @override
  String get reportsBasis =>
      'Sales use actual delivery and POS sale dates. Order counts use scheduled delivery dates. Earnings are net receipts by payment date, including corrections.';

  @override
  String get reportsSales => 'Total sales';

  @override
  String get reportsOrders => 'Total orders';

  @override
  String get reportsDelivered => 'Delivered orders';

  @override
  String get reportsCancelled => 'Cancelled orders';

  @override
  String get reportsMilk => 'Milk sold (L)';

  @override
  String reportsUnknownMilk(int count) {
    return 'Milk volume is incomplete: $count historical lines have no measured volume.';
  }

  @override
  String get reportsEarnings => 'Total earnings (net receipts)';

  @override
  String get reportsPending => 'Pending payments (current)';

  @override
  String get reportsActive => 'Active customers (current)';

  @override
  String get reportsCurrent =>
      'Pending payments and active customers are current values, independent of the selected range.';

  @override
  String get reportsProductTotal => 'Product sales';

  @override
  String get reportsCharges => 'Delivery charges';

  @override
  String get reportsDiscount => 'Discounts';

  @override
  String get reportsGap => 'Unitemized sales adjustment';

  @override
  String get reportsNoData => 'No report loaded. Connect and retry.';

  @override
  String get reportsLocked =>
      'Daily and product tables and CSV require an active BUSINESS or PREMIUM plan. Contact support for a plan change.';

  @override
  String get reportsWeekly => 'Weekly sales';

  @override
  String get reportsDaily => 'Daily sales';

  @override
  String get reportsTableHint =>
      'Swipe tables horizontally to view all columns. Long ranges use clipped Monday-based weeks.';

  @override
  String get reportsProducts => 'Product sales by sold pack';

  @override
  String get reportsNoProducts => 'No product sales in this range.';

  @override
  String reportsProductCount(int shown, int total) {
    return 'Showing through $shown of $total product groups.';
  }

  @override
  String get reportsAllProducts => 'All product groups total';

  @override
  String get reportsProduct => 'Product';

  @override
  String get reportsPack => 'Sold pack';

  @override
  String get reportsQuantity => 'Quantity (packs)';

  @override
  String get reportsPrevious => 'Previous page';

  @override
  String get reportsNext => 'Next page';

  @override
  String get reportsCsvHelp =>
      'Download the authorized CSV and choose an app to save or share it. CSV includes all product groups. Exports expire after 24 hours. Import exact large numbers as text in spreadsheets.';

  @override
  String reportsPendingExport(String from, String to) {
    return 'Retry uses the frozen CSV request for $from to $to, even if the screen range changes.';
  }

  @override
  String get reportsExportExpired =>
      'This export expired or exceeds capacity. Start a new CSV, using a smaller range if needed.';

  @override
  String get reportsChooserOpened =>
      'Share chooser opened. Choose an app to finish saving or sharing.';

  @override
  String get reportsRetryCsv => 'Download / share same CSV';

  @override
  String get reportsShareCsv => 'Download / share CSV';

  @override
  String get reportsNewCsv => 'Start a new CSV request';

  @override
  String get settingsReverifyTitle => 'Review verified details';

  @override
  String get settingsReverifyWarning =>
      'Changing your business name, PAN, bank or Aadhaar details requires a new manual review. Your shop will be hidden from customer discovery until approval. Existing records are retained.';

  @override
  String get settingsConfirm => 'Save for review';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsOffline =>
      'Offline: showing saved settings. Connect and refresh before saving.';

  @override
  String get settingsFrozen =>
      'A save is awaiting confirmation. Retry uses the same saved details and request key; editing is locked until the result is known.';

  @override
  String get settingsRetry => 'Retry saved request';

  @override
  String get settingsReviewConflict => 'Reload and review current details';

  @override
  String get settingsBusiness => 'Business information';

  @override
  String get settingsDelivery => 'Delivery settings';

  @override
  String get settingsProfile => 'Profile and account';

  @override
  String get settingsKyc => 'KYC and bank details';

  @override
  String get settingsSwitch => 'Switch to customer';

  @override
  String get settingsDelete => 'Delete account';

  @override
  String get settingsDeliveryInfo =>
      'Charges and minimum order value apply to new checkout quotes. Existing order bills stay unchanged. Same-day dates use the server IST cutoff. Checkout credit cannot be enabled here.';

  @override
  String get settingsCharge => 'Delivery charge (INR)';

  @override
  String get settingsMinimum => 'Minimum order value (INR)';

  @override
  String get settingsSlotHelp =>
      'Enter one IST slot per line, for example 07:00-08:00, 08:00-09:00 or 09:00-10:00. Saving explicitly configures these slots; blank means no checkout slots. Slots must not overlap.';

  @override
  String get settingsSlots => 'Delivery slots (HH:mm-HH:mm)';

  @override
  String get settingsSameDay => 'Accept same-day orders';

  @override
  String get settingsCutoff => 'Same-day cutoff (HH:mm IST)';

  @override
  String get settingsSave => 'Save settings';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get profilePhotoOnly => 'Choose a PNG or JPEG photo, up to 5 MB.';

  @override
  String get profilePhotoUnavailable =>
      'The profile photo could not be loaded.';

  @override
  String get profileOffline =>
      'Offline: showing saved profile details. Refresh before saving.';

  @override
  String get profileChoosePhoto => 'Choose photo';

  @override
  String get profileRemovePhoto => 'Remove photo';

  @override
  String get profilePhotoStaged =>
      'Photo change selected. Save your profile to apply it.';

  @override
  String get profileEmailNote =>
      'Email is an optional contact address. Saving it does not verify the address.';

  @override
  String get profileName => 'Name';

  @override
  String get profileEmail => 'Email (optional)';

  @override
  String get profileMobile => 'Mobile';

  @override
  String get profileMobileReadOnly => 'Your sign-in mobile is read-only.';

  @override
  String get profileSave => 'Save profile';

  @override
  String get profileSwitchRole => 'Switch role';

  @override
  String get profileAbout => 'About Supply Biz';

  @override
  String get profileClearCache => 'Clear profile cache';

  @override
  String get profileCacheHelp =>
      'Clears saved profile details and downloaded profile photos. Pending changes and offline deliveries are kept. Refresh to download the profile again.';

  @override
  String get profileNameMissing => 'Add your name';

  @override
  String get profileNoEmail => 'No contact email added';

  @override
  String get profileAddresses => 'My addresses';

  @override
  String get profileUnavailable => 'Profile unavailable. Connect and retry.';

  @override
  String profileVersion(String version) {
    return 'Version: $version';
  }

  @override
  String get profileUnknownVersion => 'Unavailable';

  @override
  String get profileLicenses => 'Open-source licenses';

  @override
  String get profileLegalUnavailable =>
      'No published document is available right now. Retry when connected.';

  @override
  String get profileLegalStale =>
      'Showing previously loaded text. Refresh to check the current published version.';

  @override
  String profileLegalVersion(String version) {
    return 'Published version: $version';
  }
}
