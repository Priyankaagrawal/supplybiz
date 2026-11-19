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

  /// No description provided for @khataTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Khata'**
  String get khataTitle;

  /// No description provided for @khataPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments & collection'**
  String get khataPayments;

  /// No description provided for @khataReceivable.
  ///
  /// In en, this message translates to:
  /// **'Total receivable'**
  String get khataReceivable;

  /// No description provided for @khataMonthReceived.
  ///
  /// In en, this message translates to:
  /// **'Khata collections this month, net of corrections'**
  String get khataMonthReceived;

  /// No description provided for @khataSettled.
  ///
  /// In en, this message translates to:
  /// **'Paid / settled'**
  String get khataSettled;

  /// No description provided for @khataDebit.
  ///
  /// In en, this message translates to:
  /// **'Debits'**
  String get khataDebit;

  /// No description provided for @khataCredit.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get khataCredit;

  /// No description provided for @khataPaid.
  ///
  /// In en, this message translates to:
  /// **'Payments received, net'**
  String get khataPaid;

  /// No description provided for @khataDue.
  ///
  /// In en, this message translates to:
  /// **'Current due / advance'**
  String get khataDue;

  /// No description provided for @khataArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived account · history only'**
  String get khataArchived;

  /// No description provided for @khataEmpty.
  ///
  /// In en, this message translates to:
  /// **'No customer accounts yet.'**
  String get khataEmpty;

  /// No description provided for @khataRecord.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get khataRecord;

  /// No description provided for @khataOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get khataOpening;

  /// No description provided for @khataReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse entry'**
  String get khataReverse;

  /// No description provided for @khataReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal / correction'**
  String get khataReversal;

  /// No description provided for @khataOriginalRetained.
  ///
  /// In en, this message translates to:
  /// **'The original entry stays in the ledger. This correction appends an opposite entry and an audit record.'**
  String get khataOriginalRetained;

  /// No description provided for @khataNoAllocation.
  ///
  /// In en, this message translates to:
  /// **'Payments are recorded against this account. Unallocated payments do not change individual order payment statuses.'**
  String get khataNoAllocation;

  /// No description provided for @khataPending.
  ///
  /// In en, this message translates to:
  /// **'An uncertain financial change is saved privately. Retry the same change before creating another; no automatic resend occurs.'**
  String get khataPending;

  /// No description provided for @khataLocked.
  ///
  /// In en, this message translates to:
  /// **'New opening balances and reversals need an active plan with Khata. History and eligible payment/claim settlement remain available after expiry.'**
  String get khataLocked;

  /// No description provided for @khataAlreadyReversed.
  ///
  /// In en, this message translates to:
  /// **'This entry already has a reversal. Refresh to review the ledger.'**
  String get khataAlreadyReversed;

  /// No description provided for @khataChanged.
  ///
  /// In en, this message translates to:
  /// **'This claim or account changed. Refresh and review before acting again.'**
  String get khataChanged;

  /// No description provided for @khataClaimExceeds.
  ///
  /// In en, this message translates to:
  /// **'The claim exceeds the current amount due. Refresh and review the claim.'**
  String get khataClaimExceeds;

  /// No description provided for @khataShowMonth.
  ///
  /// In en, this message translates to:
  /// **'Show month'**
  String get khataShowMonth;

  /// No description provided for @khataCollections.
  ///
  /// In en, this message translates to:
  /// **'Recorded collections'**
  String get khataCollections;

  /// No description provided for @khataRecordedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded {time} IST'**
  String khataRecordedAt(String time);

  /// No description provided for @khataCollectionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No collections recorded for this month.'**
  String get khataCollectionsEmpty;

  /// No description provided for @khataNetInfo.
  ///
  /// In en, this message translates to:
  /// **'Customer account payments, paid customer sales and confirmed claims are shown once. Signed corrections adjust their net total; opening credits are not payments.'**
  String get khataNetInfo;

  /// No description provided for @khataClaims.
  ///
  /// In en, this message translates to:
  /// **'Customer payment claims'**
  String get khataClaims;

  /// No description provided for @khataClaimPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get khataClaimPending;

  /// No description provided for @khataClaimConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get khataClaimConfirmed;

  /// No description provided for @khataClaimRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get khataClaimRejected;

  /// No description provided for @khataClaimInfo.
  ///
  /// In en, this message translates to:
  /// **'This is the customer’s statement, not verified payment. Confirm only after checking you received it. Confirmation records one credit; rejection requires a reason.'**
  String get khataClaimInfo;

  /// No description provided for @khataConfirmClaim.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment claim'**
  String get khataConfirmClaim;

  /// No description provided for @khataRejectClaim.
  ///
  /// In en, this message translates to:
  /// **'Reject payment claim'**
  String get khataRejectClaim;

  /// No description provided for @khataAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get khataAmount;

  /// No description provided for @khataInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount with up to two decimal places within the supported limit.'**
  String get khataInvalidAmount;

  /// No description provided for @khataEntryType.
  ///
  /// In en, this message translates to:
  /// **'Opening balance type'**
  String get khataEntryType;

  /// No description provided for @khataNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get khataNote;

  /// No description provided for @khataReceivedOn.
  ///
  /// In en, this message translates to:
  /// **'Received date'**
  String get khataReceivedOn;

  /// No description provided for @khataBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get khataBank;

  /// No description provided for @khataWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet (external record)'**
  String get khataWallet;

  /// No description provided for @salesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Sale'**
  String get salesTitle;

  /// No description provided for @salesWalkin.
  ///
  /// In en, this message translates to:
  /// **'Sale on POS'**
  String get salesWalkin;

  /// No description provided for @salesCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer Sale'**
  String get salesCustomer;

  /// No description provided for @salesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get salesSearch;

  /// No description provided for @salesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get salesAdd;

  /// No description provided for @salesQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity (whole packs)'**
  String get salesQty;

  /// No description provided for @salesRate.
  ///
  /// In en, this message translates to:
  /// **'Rate per pack (₹)'**
  String get salesRate;

  /// No description provided for @salesPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid amount'**
  String get salesPaid;

  /// No description provided for @salesBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get salesBalance;

  /// No description provided for @salesTotal.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get salesTotal;

  /// No description provided for @salesFullPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid in full'**
  String get salesFullPaid;

  /// No description provided for @salesComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete Sale'**
  String get salesComplete;

  /// No description provided for @salesNew.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get salesNew;

  /// No description provided for @salesReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get salesReceipt;

  /// No description provided for @salesReceipts.
  ///
  /// In en, this message translates to:
  /// **'Recent confirmed receipts on this device'**
  String get salesReceipts;

  /// No description provided for @salesWalkinPaid.
  ///
  /// In en, this message translates to:
  /// **'Walk-in sales must be paid in full. Select a customer to record an unpaid balance.'**
  String get salesWalkinPaid;

  /// No description provided for @salesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check whole-pack quantities, available stock and amounts (up to two decimal places). Paid cannot exceed total.'**
  String get salesInvalid;

  /// No description provided for @salesExternal.
  ///
  /// In en, this message translates to:
  /// **'Record a payment made directly to you. This does not transfer money or verify a UPI payment.'**
  String get salesExternal;

  /// No description provided for @salesCached.
  ///
  /// In en, this message translates to:
  /// **'Saved catalog. Prices, products, customer eligibility, plan and stock are checked when the sale syncs.'**
  String get salesCached;

  /// No description provided for @salesLocked.
  ///
  /// In en, this message translates to:
  /// **'Quick Sale needs an active eligible plan. Contact support, then explicitly retry the saved sale.'**
  String get salesLocked;

  /// No description provided for @salesCustomerMissing.
  ///
  /// In en, this message translates to:
  /// **'The selected customer is no longer available. Refresh and review the sale.'**
  String get salesCustomerMissing;

  /// No description provided for @salesQueue.
  ///
  /// In en, this message translates to:
  /// **'Sale sync queue'**
  String get salesQueue;

  /// No description provided for @salesQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending sales.'**
  String get salesQueueEmpty;

  /// No description provided for @salesQueueInfo.
  ///
  /// In en, this message translates to:
  /// **'Pending sales reserve local stock. Only a server receipt confirms a completed sale. Uncertain sends keep the same reference when retried.'**
  String get salesQueueInfo;

  /// No description provided for @salesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry saved sales'**
  String get salesRetry;

  /// No description provided for @salesPending.
  ///
  /// In en, this message translates to:
  /// **'Saved locally · Pending sync'**
  String get salesPending;

  /// No description provided for @salesRejected.
  ///
  /// In en, this message translates to:
  /// **'Not completed · Review and enter a new sale'**
  String get salesRejected;

  /// No description provided for @salesNeedsRetry.
  ///
  /// In en, this message translates to:
  /// **'Needs explicit retry'**
  String get salesNeedsRetry;

  /// No description provided for @salesDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard unsent or rejected sale'**
  String get salesDiscard;

  /// No description provided for @salesDiscardInfo.
  ///
  /// In en, this message translates to:
  /// **'Remove this local record. A sale with an uncertain server result cannot be discarded.'**
  String get salesDiscardInfo;

  /// No description provided for @salesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available after pending sales: {count}'**
  String salesAvailable(int count);

  /// No description provided for @salesItemCount.
  ///
  /// In en, this message translates to:
  /// **'Total packs: {count}'**
  String salesItemCount(int count);

  /// No description provided for @salesConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Sale confirmed: {number}'**
  String salesConfirmed(String number);

  /// No description provided for @salesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from sale'**
  String salesRemove(String name);

  /// No description provided for @availabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability & holidays'**
  String get availabilityTitle;

  /// No description provided for @availabilityAccepting.
  ///
  /// In en, this message translates to:
  /// **'Accepting deliveries today'**
  String get availabilityAccepting;

  /// No description provided for @availabilityAcceptingInfo.
  ///
  /// In en, this message translates to:
  /// **'Turning this off stops new one-time orders for today. Existing orders and subscriptions remain.'**
  String get availabilityAcceptingInfo;

  /// No description provided for @availabilityPause.
  ///
  /// In en, this message translates to:
  /// **'Pause deliveries'**
  String get availabilityPause;

  /// No description provided for @availabilityResume.
  ///
  /// In en, this message translates to:
  /// **'Resume deliveries'**
  String get availabilityResume;

  /// No description provided for @availabilityPaused.
  ///
  /// In en, this message translates to:
  /// **'Deliveries paused'**
  String get availabilityPaused;

  /// No description provided for @availabilityRunning.
  ///
  /// In en, this message translates to:
  /// **'Deliveries running'**
  String get availabilityRunning;

  /// No description provided for @availabilityPauseInfo.
  ///
  /// In en, this message translates to:
  /// **'Pause deliveries until you choose Resume. Eligible orders from today onward will be cancelled. Out-for-delivery and completed orders remain.'**
  String get availabilityPauseInfo;

  /// No description provided for @availabilityResumeInfo.
  ///
  /// In en, this message translates to:
  /// **'Restore future delivery eligibility. Previously cancelled orders are not restored.'**
  String get availabilityResumeInfo;

  /// No description provided for @availabilityMarkHoliday.
  ///
  /// In en, this message translates to:
  /// **'Mark holiday'**
  String get availabilityMarkHoliday;

  /// No description provided for @availabilityDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete holiday'**
  String get availabilityDelete;

  /// No description provided for @availabilityDate.
  ///
  /// In en, this message translates to:
  /// **'Holiday date'**
  String get availabilityDate;

  /// No description provided for @availabilityFutureOnly.
  ///
  /// In en, this message translates to:
  /// **'Only a future holiday can be deleted.'**
  String get availabilityFutureOnly;

  /// No description provided for @availabilityExists.
  ///
  /// In en, this message translates to:
  /// **'A holiday already exists on this date. Refresh to view it.'**
  String get availabilityExists;

  /// No description provided for @availabilityConflict.
  ///
  /// In en, this message translates to:
  /// **'Settings changed. Refresh and review before trying again.'**
  String get availabilityConflict;

  /// No description provided for @availabilitySaved.
  ///
  /// In en, this message translates to:
  /// **'Change saved.'**
  String get availabilitySaved;

  /// No description provided for @availabilityPlanLocked.
  ///
  /// In en, this message translates to:
  /// **'Enabling deliveries or deleting holidays requires an active plan. History and reducing controls remain available. Contact support about a plan change.'**
  String get availabilityPlanLocked;

  /// No description provided for @availabilityImpactInfo.
  ///
  /// In en, this message translates to:
  /// **'This is a preview. The affected count is checked again when saving. Eligible customers will be notified; no refund or payment reversal is recorded.'**
  String get availabilityImpactInfo;

  /// No description provided for @availabilityImpact.
  ///
  /// In en, this message translates to:
  /// **'{count} existing orders will be cancelled.'**
  String availabilityImpact(int count);

  /// No description provided for @availabilityCancelled.
  ///
  /// In en, this message translates to:
  /// **'Saved. {count} orders cancelled.'**
  String availabilityCancelled(int count);

  /// No description provided for @availabilityBusinessDate.
  ///
  /// In en, this message translates to:
  /// **'Today: {date} (IST)'**
  String availabilityBusinessDate(String date);

  /// No description provided for @availabilityLegacyEnd.
  ///
  /// In en, this message translates to:
  /// **'Existing pause ends at {time} IST.'**
  String availabilityLegacyEnd(String time);

  /// No description provided for @customerSubPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscription plans'**
  String get customerSubPlans;

  /// No description provided for @customerSubMine.
  ///
  /// In en, this message translates to:
  /// **'My subscriptions'**
  String get customerSubMine;

  /// No description provided for @customerSubMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get customerSubMore;

  /// No description provided for @customerSubCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom plan'**
  String get customerSubCustom;

  /// No description provided for @customerSubPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get customerSubPopular;

  /// No description provided for @customerSubFree.
  ///
  /// In en, this message translates to:
  /// **'Free delivery'**
  String get customerSubFree;

  /// No description provided for @customerSubFeatures.
  ///
  /// In en, this message translates to:
  /// **'Pause or skip anytime · Monthly billing · Manage from app'**
  String get customerSubFeatures;

  /// No description provided for @customerSubAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get customerSubAddress;

  /// No description provided for @customerSubConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm subscription'**
  String get customerSubConfirm;

  /// No description provided for @customerSubCashOnly.
  ///
  /// In en, this message translates to:
  /// **'The vendor has not set a payment UPI ID. Cash is the only available option.'**
  String get customerSubCashOnly;

  /// No description provided for @customerSubStatement.
  ///
  /// In en, this message translates to:
  /// **'Monthly statement'**
  String get customerSubStatement;

  /// No description provided for @customerSubMonth.
  ///
  /// In en, this message translates to:
  /// **'Month (YYYY-MM)'**
  String get customerSubMonth;

  /// No description provided for @customerSubDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered subscription orders'**
  String get customerSubDelivered;

  /// No description provided for @customerSubLedger.
  ///
  /// In en, this message translates to:
  /// **'Shared vendor account: payments and balances include all purchases. Unallocated payments are not assigned to this subscription.'**
  String get customerSubLedger;

  /// No description provided for @customerSubOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get customerSubOpening;

  /// No description provided for @customerSubClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing balance'**
  String get customerSubClosing;

  /// No description provided for @customerSubPaid.
  ///
  /// In en, this message translates to:
  /// **'Payments recorded this month'**
  String get customerSubPaid;

  /// No description provided for @customerSubCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current vendor balance'**
  String get customerSubCurrent;

  /// No description provided for @customerSubAmount.
  ///
  /// In en, this message translates to:
  /// **'Delivered amount'**
  String get customerSubAmount;

  /// No description provided for @customerSubQuantity.
  ///
  /// In en, this message translates to:
  /// **'Delivered packs'**
  String get customerSubQuantity;

  /// No description provided for @customerSubCutoffError.
  ///
  /// In en, this message translates to:
  /// **'That date is frozen by the 21:00 IST cutoff. Refresh and choose the next eligible delivery date.'**
  String get customerSubCutoffError;

  /// No description provided for @customerSubLink.
  ///
  /// In en, this message translates to:
  /// **'Accept the vendor’s customer-link request on Home before subscribing.'**
  String get customerSubLink;

  /// No description provided for @customerSubEmptyStatement.
  ///
  /// In en, this message translates to:
  /// **'No delivered orders for this subscription in this month.'**
  String get customerSubEmptyStatement;

  /// No description provided for @subTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subTitle;

  /// No description provided for @subSettings.
  ///
  /// In en, this message translates to:
  /// **'Subscription settings'**
  String get subSettings;

  /// No description provided for @subCreate.
  ///
  /// In en, this message translates to:
  /// **'Create subscription'**
  String get subCreate;

  /// No description provided for @subActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subActive;

  /// No description provided for @subPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get subPaused;

  /// No description provided for @subPending.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get subPending;

  /// No description provided for @subCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subCancelled;

  /// No description provided for @subRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get subRejected;

  /// No description provided for @subCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get subCompleted;

  /// No description provided for @subApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get subApprove;

  /// No description provided for @subReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get subReject;

  /// No description provided for @subPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get subPause;

  /// No description provided for @subResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get subResume;

  /// No description provided for @subSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip a date'**
  String get subSkip;

  /// No description provided for @subCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get subCancel;

  /// No description provided for @subSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get subSave;

  /// No description provided for @subMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get subMon;

  /// No description provided for @subTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get subTue;

  /// No description provided for @subWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get subWed;

  /// No description provided for @subThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get subThu;

  /// No description provided for @subFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get subFri;

  /// No description provided for @subSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get subSat;

  /// No description provided for @subSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get subSun;

  /// No description provided for @subDailyDays.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get subDailyDays;

  /// No description provided for @subEmpty.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions match your selection.'**
  String get subEmpty;

  /// No description provided for @subOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved data. Refresh online before making changes.'**
  String get subOffline;

  /// No description provided for @subSaved.
  ///
  /// In en, this message translates to:
  /// **'A saved change needs acknowledgement. Retry the same change before making another.'**
  String get subSaved;

  /// No description provided for @subRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry saved change'**
  String get subRetry;

  /// No description provided for @subReviewExpired.
  ///
  /// In en, this message translates to:
  /// **'Reload and review expired settings change'**
  String get subReviewExpired;

  /// No description provided for @subPlanLocked.
  ///
  /// In en, this message translates to:
  /// **'Creating, editing and resuming subscriptions requires an active STANDARD or higher plan. Contact support about a plan change. History and reducing controls remain available.'**
  String get subPlanLocked;

  /// No description provided for @subBusinessGuidance.
  ///
  /// In en, this message translates to:
  /// **'Enabling auto-accept requires BUSINESS or higher. Contact support about a plan change.'**
  String get subBusinessGuidance;

  /// No description provided for @subAutoAccept.
  ///
  /// In en, this message translates to:
  /// **'Automatically accept subscription orders'**
  String get subAutoAccept;

  /// No description provided for @subAutoEffective.
  ///
  /// In en, this message translates to:
  /// **'Auto-accept is effective for the current plan.'**
  String get subAutoEffective;

  /// No description provided for @subAutoInactive.
  ///
  /// In en, this message translates to:
  /// **'Auto-accept is not effective for the current configuration and plan.'**
  String get subAutoInactive;

  /// No description provided for @subAvailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription delivery available'**
  String get subAvailable;

  /// No description provided for @subPauseAll.
  ///
  /// In en, this message translates to:
  /// **'Pause all subscriptions'**
  String get subPauseAll;

  /// No description provided for @subCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get subCustomer;

  /// No description provided for @subProduct.
  ///
  /// In en, this message translates to:
  /// **'Product and price per pack'**
  String get subProduct;

  /// No description provided for @subQty.
  ///
  /// In en, this message translates to:
  /// **'Whole packs per delivery'**
  String get subQty;

  /// No description provided for @subLess.
  ///
  /// In en, this message translates to:
  /// **'Decrease packs per delivery'**
  String get subLess;

  /// No description provided for @subMore.
  ///
  /// In en, this message translates to:
  /// **'Increase packs per delivery'**
  String get subMore;

  /// No description provided for @subStart.
  ///
  /// In en, this message translates to:
  /// **'Start date (YYYY-MM-DD)'**
  String get subStart;

  /// No description provided for @subEnd.
  ///
  /// In en, this message translates to:
  /// **'End date, optional (YYYY-MM-DD)'**
  String get subEnd;

  /// No description provided for @subFrom.
  ///
  /// In en, this message translates to:
  /// **'Delivery date (YYYY-MM-DD)'**
  String get subFrom;

  /// No description provided for @subSlot.
  ///
  /// In en, this message translates to:
  /// **'Configured delivery slot'**
  String get subSlot;

  /// No description provided for @subPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment preference'**
  String get subPayment;

  /// No description provided for @subReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get subReason;

  /// No description provided for @subNoEnd.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get subNoEnd;

  /// No description provided for @subInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the required selection, whole-pack quantity, days and date or time format.'**
  String get subInvalid;

  /// No description provided for @subCutoff.
  ///
  /// In en, this message translates to:
  /// **'Customer changes close at 21:00 IST before delivery. Changes after cutoff apply from the next eligible date shown by the server. Existing generated orders remain; use Skip to cancel an eligible dated order.'**
  String get subCutoff;

  /// No description provided for @subCancelInfo.
  ///
  /// In en, this message translates to:
  /// **'Stop future subscription deliveries. Existing generated orders are retained.'**
  String get subCancelInfo;

  /// No description provided for @subPostpaid.
  ///
  /// In en, this message translates to:
  /// **'Monthly amounts are estimates for the selected start month. Postpaid Khata is billed only when an order is delivered; no payment is taken during setup.'**
  String get subPostpaid;

  /// No description provided for @subConfirmSettings.
  ///
  /// In en, this message translates to:
  /// **'Confirm subscription setting change'**
  String get subConfirmSettings;

  /// No description provided for @subSettingsEffect.
  ///
  /// In en, this message translates to:
  /// **'This changes future generation eligibility. Individual subscriptions and existing orders are retained.'**
  String get subSettingsEffect;

  /// No description provided for @subLimitsInfo.
  ///
  /// In en, this message translates to:
  /// **'Limits are shared with other orders. Leave a limit blank for unlimited; clear both times to remove the delivery window. Times are IST; overnight windows are allowed.'**
  String get subLimitsInfo;

  /// No description provided for @subOrderCap.
  ///
  /// In en, this message translates to:
  /// **'Daily order limit, optional'**
  String get subOrderCap;

  /// No description provided for @subMilkCap.
  ///
  /// In en, this message translates to:
  /// **'Daily milk capacity in litres, optional (up to 3 decimal places)'**
  String get subMilkCap;

  /// No description provided for @subWindowStart.
  ///
  /// In en, this message translates to:
  /// **'Delivery window start (HH:mm IST)'**
  String get subWindowStart;

  /// No description provided for @subWindowEnd.
  ///
  /// In en, this message translates to:
  /// **'Delivery window end (HH:mm IST)'**
  String get subWindowEnd;

  /// No description provided for @subMoney.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}'**
  String subMoney(String amount);

  /// No description provided for @subDaily.
  ///
  /// In en, this message translates to:
  /// **'Per delivery: {amount}'**
  String subDaily(String amount);

  /// No description provided for @subMonthly.
  ///
  /// In en, this message translates to:
  /// **'Estimated {month}: {amount}'**
  String subMonthly(String amount, String month);

  /// No description provided for @subEffective.
  ///
  /// In en, this message translates to:
  /// **'Change recorded, effective from {date}.'**
  String subEffective(String date);

  /// No description provided for @subQuantityValue.
  ///
  /// In en, this message translates to:
  /// **'{qty} packs · {slot}'**
  String subQuantityValue(int qty, String slot);

  /// No description provided for @subDates.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String subDates(String start, String end);

  /// No description provided for @subPausedDates.
  ///
  /// In en, this message translates to:
  /// **'Pause: {start} to {end}'**
  String subPausedDates(String start, String end);

  /// No description provided for @subSkippedDate.
  ///
  /// In en, this message translates to:
  /// **'Skipped: {date}'**
  String subSkippedDate(String date);

  /// No description provided for @subSummary.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions: {total} · Active: {active} · Paused: {paused} · Pending approval: {pending} · Customers: {customers}'**
  String subSummary(
      int total, int active, int paused, int pending, int customers);

  /// No description provided for @deliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveryTitle;

  /// No description provided for @deliveryQueue.
  ///
  /// In en, this message translates to:
  /// **'Sync queue'**
  String get deliveryQueue;

  /// No description provided for @deliveryCached.
  ///
  /// In en, this message translates to:
  /// **'Cached deliveries. Updates stay pending until the server confirms them.'**
  String get deliveryCached;

  /// No description provided for @deliveryPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get deliveryPending;

  /// No description provided for @deliveryPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get deliveryPendingSync;

  /// No description provided for @deliveryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deliveries for this date'**
  String get deliveryEmpty;

  /// No description provided for @deliveryQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No queued delivery updates'**
  String get deliveryQueueEmpty;

  /// No description provided for @deliveryQueueHelp.
  ///
  /// In en, this message translates to:
  /// **'Updates sync automatically when connected, including Android background sync when allowed by your device. Open the app to check progress. Uncertain updates must be retried with their saved key.'**
  String get deliveryQueueHelp;

  /// No description provided for @deliveryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry saved delivery updates'**
  String get deliveryRetry;

  /// No description provided for @deliveryRejected.
  ///
  /// In en, this message translates to:
  /// **'Update rejected'**
  String get deliveryRejected;

  /// No description provided for @deliveryRetryNeeded.
  ///
  /// In en, this message translates to:
  /// **'Automatic retries stopped. Retry when the connection or access is restored.'**
  String get deliveryRetryNeeded;

  /// No description provided for @deliveryRollback.
  ///
  /// In en, this message translates to:
  /// **'The pending change was rolled back. Refresh deliveries, discard this rejected update, then check the current status before trying again.'**
  String get deliveryRollback;

  /// No description provided for @deliveryDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard update'**
  String get deliveryDiscard;

  /// No description provided for @deliveryDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard this update and its unsent dependent updates?'**
  String get deliveryDiscardConfirm;

  /// No description provided for @deliveryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deliveryCancel;

  /// No description provided for @deliveryDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark delivered'**
  String get deliveryDelivered;

  /// No description provided for @deliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Mark failed'**
  String get deliveryFailed;

  /// No description provided for @deliveryReason.
  ///
  /// In en, this message translates to:
  /// **'Failure reason'**
  String get deliveryReason;

  /// No description provided for @deliveryReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a failure reason.'**
  String get deliveryReasonRequired;

  /// No description provided for @deliveryCollected.
  ///
  /// In en, this message translates to:
  /// **'Payment collected?'**
  String get deliveryCollected;

  /// No description provided for @deliveryMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get deliveryMethod;

  /// No description provided for @deliveryAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount collected (₹)'**
  String get deliveryAmount;

  /// No description provided for @deliveryAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero with at most two decimal places.'**
  String get deliveryAmountInvalid;

  /// No description provided for @customerOrdersOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get customerOrdersOngoing;

  /// No description provided for @customerOrdersCallVendor.
  ///
  /// In en, this message translates to:
  /// **'Call vendor'**
  String get customerOrdersCallVendor;

  /// No description provided for @customerOrdersCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get customerOrdersCancel;

  /// No description provided for @customerOrdersCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this new order? There is no cancellation fee.'**
  String get customerOrdersCancelConfirm;

  /// No description provided for @customerOrdersReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get customerOrdersReorder;

  /// No description provided for @customerOrdersReview.
  ///
  /// In en, this message translates to:
  /// **'Review current prices and availability'**
  String get customerOrdersReview;

  /// No description provided for @customerOrdersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add available items to cart'**
  String get customerOrdersAdd;

  /// No description provided for @customerOrdersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable items'**
  String get customerOrdersUnavailable;

  /// No description provided for @customerOrdersNoStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock for the saved quantity'**
  String get customerOrdersNoStock;

  /// No description provided for @customerOrdersMoq.
  ///
  /// In en, this message translates to:
  /// **'The saved quantity is below the current minimum'**
  String get customerOrdersMoq;

  /// No description provided for @customerOrdersRemoved.
  ///
  /// In en, this message translates to:
  /// **'Product is no longer available'**
  String get customerOrdersRemoved;

  /// No description provided for @customerOrdersConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get customerOrdersConfirmed;

  /// No description provided for @customerOrdersPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get customerOrdersPacked;

  /// No description provided for @customerOrdersNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not reached'**
  String get customerOrdersNotYet;

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

  /// No description provided for @ordersFilter.
  ///
  /// In en, this message translates to:
  /// **'Order status'**
  String get ordersFilter;

  /// No description provided for @ordersSearch.
  ///
  /// In en, this message translates to:
  /// **'Search customer name or order number'**
  String get ordersSearch;

  /// No description provided for @ordersDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date (YYYY-MM-DD, IST)'**
  String get ordersDate;

  /// No description provided for @ordersInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date as YYYY-MM-DD.'**
  String get ordersInvalidDate;

  /// No description provided for @ordersAllDates.
  ///
  /// In en, this message translates to:
  /// **'All delivery dates'**
  String get ordersAllDates;

  /// No description provided for @ordersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders found.'**
  String get ordersEmpty;

  /// No description provided for @ordersOpen.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get ordersOpen;

  /// No description provided for @ordersMore.
  ///
  /// In en, this message translates to:
  /// **'Load more orders'**
  String get ordersMore;

  /// No description provided for @ordersDetails.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get ordersDetails;

  /// No description provided for @ordersCached.
  ///
  /// In en, this message translates to:
  /// **'Showing saved order data. Refresh online before changing an order.'**
  String get ordersCached;

  /// No description provided for @ordersPending.
  ///
  /// In en, this message translates to:
  /// **'An order update is awaiting confirmation. Retry the saved update before making another change.'**
  String get ordersPending;

  /// No description provided for @ordersRetrySaved.
  ///
  /// In en, this message translates to:
  /// **'Retry saved order update'**
  String get ordersRetrySaved;

  /// No description provided for @ordersNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Order no longer available for that action. The latest order has been refreshed.'**
  String get ordersNoLongerAvailable;

  /// No description provided for @ordersItems.
  ///
  /// In en, this message translates to:
  /// **'Order items'**
  String get ordersItems;

  /// No description provided for @ordersDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount: {amount}'**
  String ordersDiscount(String amount);

  /// No description provided for @ordersPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get ordersPaid;

  /// No description provided for @ordersUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get ordersUnpaid;

  /// No description provided for @ordersApp.
  ///
  /// In en, this message translates to:
  /// **'App order'**
  String get ordersApp;

  /// No description provided for @ordersVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor-created order'**
  String get ordersVendor;

  /// No description provided for @ordersTimeline.
  ///
  /// In en, this message translates to:
  /// **'Status timeline'**
  String get ordersTimeline;

  /// No description provided for @ordersIst.
  ///
  /// In en, this message translates to:
  /// **'IST'**
  String get ordersIst;

  /// No description provided for @ordersAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept order'**
  String get ordersAccept;

  /// No description provided for @ordersReject.
  ///
  /// In en, this message translates to:
  /// **'Reject order'**
  String get ordersReject;

  /// No description provided for @ordersPacked.
  ///
  /// In en, this message translates to:
  /// **'Mark packed'**
  String get ordersPacked;

  /// No description provided for @ordersStartDelivery.
  ///
  /// In en, this message translates to:
  /// **'Start delivery'**
  String get ordersStartDelivery;

  /// No description provided for @ordersReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get ordersReason;

  /// No description provided for @ordersReasonHelp.
  ///
  /// In en, this message translates to:
  /// **'Explain the reason in 5–200 characters.'**
  String get ordersReasonHelp;

  /// No description provided for @ordersCustomerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Customer not available'**
  String get ordersCustomerUnavailable;

  /// No description provided for @ordersOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Product out of stock'**
  String get ordersOutOfStock;

  /// No description provided for @ordersNotServiceable.
  ///
  /// In en, this message translates to:
  /// **'Area not serviceable'**
  String get ordersNotServiceable;

  /// No description provided for @ordersCustomerRequest.
  ///
  /// In en, this message translates to:
  /// **'Customer requested to cancel'**
  String get ordersCustomerRequest;

  /// No description provided for @ordersOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ordersOther;

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

  /// No description provided for @linkTitle.
  ///
  /// In en, this message translates to:
  /// **'Link vendor accounts'**
  String get linkTitle;

  /// No description provided for @linkMore.
  ///
  /// In en, this message translates to:
  /// **'Show more account links'**
  String get linkMore;

  /// No description provided for @linkAccept.
  ///
  /// In en, this message translates to:
  /// **'Link account'**
  String get linkAccept;

  /// No description provided for @linkDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline link'**
  String get linkDecline;

  /// No description provided for @linkConsent.
  ///
  /// In en, this message translates to:
  /// **'Link your account with {name}? This connects the vendor\'s existing customer records to your signed-in account.'**
  String linkConsent(String name);

  /// No description provided for @linkDeclineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Decline the link from {name}? This request will be dismissed and its records will stay unlinked.'**
  String linkDeclineConfirm(String name);

  /// No description provided for @linkAccepted.
  ///
  /// In en, this message translates to:
  /// **'Account linked.'**
  String get linkAccepted;

  /// No description provided for @linkDeclined.
  ///
  /// In en, this message translates to:
  /// **'Link declined.'**
  String get linkDeclined;

  /// No description provided for @linkEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vendor accounts waiting to be linked.'**
  String get linkEmpty;

  /// No description provided for @linkRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh account links'**
  String get linkRefresh;

  /// No description provided for @linkPendingAccept.
  ///
  /// In en, this message translates to:
  /// **'Your link request is awaiting confirmation. Retry the saved acceptance to check its result.'**
  String get linkPendingAccept;

  /// No description provided for @linkPendingDecline.
  ///
  /// In en, this message translates to:
  /// **'Your decline is awaiting confirmation. Retry the saved decision to check its result.'**
  String get linkPendingDecline;

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

  /// No description provided for @customerKhataPayable.
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get customerKhataPayable;

  /// No description provided for @customerKhataNet.
  ///
  /// In en, this message translates to:
  /// **'Net balance'**
  String get customerKhataNet;

  /// No description provided for @customerKhataVendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get customerKhataVendors;

  /// No description provided for @customerKhataPersonal.
  ///
  /// In en, this message translates to:
  /// **'Customers (personal)'**
  String get customerKhataPersonal;

  /// No description provided for @customerKhataAdd.
  ///
  /// In en, this message translates to:
  /// **'Add personal contact'**
  String get customerKhataAdd;

  /// No description provided for @customerKhataEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get customerKhataEdit;

  /// No description provided for @customerKhataDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get customerKhataDelete;

  /// No description provided for @customerKhataDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this personal contact and its personal entries?'**
  String get customerKhataDeleteConfirm;

  /// No description provided for @customerKhataName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get customerKhataName;

  /// No description provided for @customerKhataMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile (optional)'**
  String get customerKhataMobile;

  /// No description provided for @customerKhataGave.
  ///
  /// In en, this message translates to:
  /// **'Gave'**
  String get customerKhataGave;

  /// No description provided for @customerKhataGot.
  ///
  /// In en, this message translates to:
  /// **'Got'**
  String get customerKhataGot;

  /// No description provided for @customerKhataAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add personal entry'**
  String get customerKhataAddEntry;

  /// No description provided for @customerKhataEditEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit personal entry'**
  String get customerKhataEditEntry;

  /// No description provided for @customerKhataDeleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get customerKhataDeleteEntry;

  /// No description provided for @customerKhataDeleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this personal entry?'**
  String get customerKhataDeleteEntryConfirm;

  /// No description provided for @customerKhataBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get customerKhataBalance;

  /// No description provided for @customerKhataSettle.
  ///
  /// In en, this message translates to:
  /// **'Settle dues'**
  String get customerKhataSettle;

  /// No description provided for @customerKhataCashOnly.
  ///
  /// In en, this message translates to:
  /// **'This vendor has no published payment UPI ID. Only cash is available.'**
  String get customerKhataCashOnly;

  /// No description provided for @customerKhataCash.
  ///
  /// In en, this message translates to:
  /// **'I paid cash - submit claim'**
  String get customerKhataCash;

  /// No description provided for @customerKhataUpi.
  ///
  /// In en, this message translates to:
  /// **'Open UPI app'**
  String get customerKhataUpi;

  /// No description provided for @customerKhataPaid.
  ///
  /// In en, this message translates to:
  /// **'I\'ve paid'**
  String get customerKhataPaid;

  /// No description provided for @customerKhataNotPaid.
  ///
  /// In en, this message translates to:
  /// **'I did not pay - discard draft'**
  String get customerKhataNotPaid;

  /// No description provided for @customerKhataReview.
  ///
  /// In en, this message translates to:
  /// **'Did you pay? Submit only if you actually paid. Your claim stays pending until the vendor confirms it.'**
  String get customerKhataReview;

  /// No description provided for @customerKhataFallback.
  ///
  /// In en, this message translates to:
  /// **'No UPI app opened. Use this payment QR or copy the UPI ID to pay from another device.'**
  String get customerKhataFallback;

  /// No description provided for @customerKhataQr.
  ///
  /// In en, this message translates to:
  /// **'Payment QR code'**
  String get customerKhataQr;

  /// No description provided for @customerKhataCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy UPI ID'**
  String get customerKhataCopy;

  /// No description provided for @customerKhataCopied.
  ///
  /// In en, this message translates to:
  /// **'UPI ID copied'**
  String get customerKhataCopied;

  /// No description provided for @customerKhataPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payee and payment details'**
  String get customerKhataPaymentDetails;

  /// No description provided for @customerKhataAccount.
  ///
  /// In en, this message translates to:
  /// **'Billing account'**
  String get customerKhataAccount;

  /// No description provided for @customerKhataDueLimit.
  ///
  /// In en, this message translates to:
  /// **'Claim limit'**
  String get customerKhataDueLimit;

  /// No description provided for @customerKhataInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name, mobile, date and positive amount as applicable. The amount must not exceed the current due or claim limit.'**
  String get customerKhataInvalid;

  /// No description provided for @customerKhataChanged.
  ///
  /// In en, this message translates to:
  /// **'Payment details or dues changed. Refresh and review before paying.'**
  String get customerKhataChanged;

  /// No description provided for @customerKhataSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Payment claims remain pending until vendor confirmation.'**
  String get customerKhataSaved;

  /// No description provided for @customerKhataSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get customerKhataSource;

  /// No description provided for @customerKhataUnallocated.
  ///
  /// In en, this message translates to:
  /// **'No source payment allocation recorded'**
  String get customerKhataUnallocated;

  /// No description provided for @customerKhataDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get customerKhataDirection;

  /// No description provided for @customerKhataMonthTotal.
  ///
  /// In en, this message translates to:
  /// **'Month payable'**
  String get customerKhataMonthTotal;

  /// No description provided for @customerKhataMonthPaid.
  ///
  /// In en, this message translates to:
  /// **'Month paid'**
  String get customerKhataMonthPaid;

  /// No description provided for @customerKhataNoDue.
  ///
  /// In en, this message translates to:
  /// **'No eligible outstanding due.'**
  String get customerKhataNoDue;

  /// No description provided for @customerKhataPendingReview.
  ///
  /// In en, this message translates to:
  /// **'A payment draft is saved. Review it before starting another payment.'**
  String get customerKhataPendingReview;

  /// No description provided for @customerKhataConfirmCash.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you already paid this amount in cash. This submits a pending claim for vendor review.'**
  String get customerKhataConfirmCash;

  /// No description provided for @customerKhataApplyMonth.
  ///
  /// In en, this message translates to:
  /// **'Apply month'**
  String get customerKhataApplyMonth;

  /// No description provided for @customerKhataInvalidMonth.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid month as YYYY-MM.'**
  String get customerKhataInvalidMonth;

  /// No description provided for @customerKhataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get customerKhataConfirm;

  /// No description provided for @customerKhataMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get customerKhataMethodCash;

  /// No description provided for @customerKhataMethodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get customerKhataMethodUpi;

  /// No description provided for @dashShopPhoto.
  ///
  /// In en, this message translates to:
  /// **'Shop photo'**
  String get dashShopPhoto;

  /// No description provided for @dashShopMissing.
  ///
  /// In en, this message translates to:
  /// **'Your shop'**
  String get dashShopMissing;

  /// No description provided for @dashCityMissing.
  ///
  /// In en, this message translates to:
  /// **'City not set'**
  String get dashCityMissing;

  /// No description provided for @dashSelectedDate.
  ///
  /// In en, this message translates to:
  /// **'Selected IST date: {date}'**
  String dashSelectedDate(String date);

  /// No description provided for @dashApplyDate.
  ///
  /// In en, this message translates to:
  /// **'Apply date'**
  String get dashApplyDate;

  /// No description provided for @dashToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashToday;

  /// No description provided for @dashOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders for date'**
  String get dashOrders;

  /// No description provided for @dashPending.
  ///
  /// In en, this message translates to:
  /// **'Pending orders'**
  String get dashPending;

  /// No description provided for @dashCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed orders'**
  String get dashCompleted;

  /// No description provided for @dashSales.
  ///
  /// In en, this message translates to:
  /// **'Recorded sales for date'**
  String get dashSales;

  /// No description provided for @dashLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime recorded sales'**
  String get dashLifetime;

  /// No description provided for @dashMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk stock'**
  String get dashMilk;

  /// No description provided for @dashCustomers.
  ///
  /// In en, this message translates to:
  /// **'Active customers'**
  String get dashCustomers;

  /// No description provided for @dashLitres.
  ///
  /// In en, this message translates to:
  /// **'{value} L'**
  String dashLitres(String value);

  /// No description provided for @dashReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get dashReports;

  /// No description provided for @dashReportsSoon.
  ///
  /// In en, this message translates to:
  /// **'Reports available soon'**
  String get dashReportsSoon;

  /// No description provided for @dashScheduledInfo.
  ///
  /// In en, this message translates to:
  /// **'Order counts use the scheduled delivery date. Pending includes new, accepted, preparing and out-for-delivery orders.'**
  String get dashScheduledInfo;

  /// No description provided for @dashGrossInfo.
  ///
  /// In en, this message translates to:
  /// **'Sales include delivered orders and Quick Sales, including delivery charges. They represent recorded sales, not payments received or profit.'**
  String get dashGrossInfo;

  /// No description provided for @dashCurrentInfo.
  ///
  /// In en, this message translates to:
  /// **'Milk stock and active customers show the current state, regardless of selected date.'**
  String get dashCurrentInfo;

  /// No description provided for @dashUnknownMilk.
  ///
  /// In en, this message translates to:
  /// **'{count} stocked milk products have units that cannot be converted to litres. Shown volume is incomplete.'**
  String dashUnknownMilk(int count);

  /// No description provided for @dashActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashActions;

  /// No description provided for @dashNoCache.
  ///
  /// In en, this message translates to:
  /// **'No dashboard data saved for this date. Connect and refresh.'**
  String get dashNoCache;

  /// No description provided for @dashUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {time} IST'**
  String dashUpdated(String time);

  /// No description provided for @dashOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved dashboard data. Connect and refresh for current values.'**
  String get dashOffline;

  /// No description provided for @dashCacheUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not save the dashboard for offline use.'**
  String get dashCacheUnavailable;

  /// No description provided for @dashVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification is incomplete. Your shop is hidden from customer discovery until verified.'**
  String get dashVerification;

  /// No description provided for @dashPlanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Plan details are unavailable. Refresh to check your current access.'**
  String get dashPlanUnavailable;

  /// No description provided for @dashPlanExpired.
  ///
  /// In en, this message translates to:
  /// **'Your plan has expired. History and eligible settlement remain available.'**
  String get dashPlanExpired;

  /// No description provided for @dashPlanScheduled.
  ///
  /// In en, this message translates to:
  /// **'Your plan is scheduled to start later. Paid features require an active assignment.'**
  String get dashPlanScheduled;

  /// No description provided for @dashPlanUnassigned.
  ///
  /// In en, this message translates to:
  /// **'No plan is assigned. Setup allowance does not unlock paid features.'**
  String get dashPlanUnassigned;

  /// No description provided for @dashPlanSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support for plan assignment or renewal.'**
  String get dashPlanSupport;

  /// No description provided for @dashAvailableSoon.
  ///
  /// In en, this message translates to:
  /// **'Available soon'**
  String get dashAvailableSoon;

  /// No description provided for @dashPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get dashPlans;

  /// No description provided for @dashVendorSettings.
  ///
  /// In en, this message translates to:
  /// **'Vendor settings'**
  String get dashVendorSettings;

  /// No description provided for @dashHelp.
  ///
  /// In en, this message translates to:
  /// **'Help and FAQ'**
  String get dashHelp;

  /// No description provided for @dashAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account and security'**
  String get dashAccountSettings;

  /// No description provided for @dashSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get dashSubscriptions;

  /// No description provided for @dashDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get dashDeliveries;

  /// No description provided for @dashActiveProducts.
  ///
  /// In en, this message translates to:
  /// **'Showing active products'**
  String get dashActiveProducts;

  /// No description provided for @plansView.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get plansView;

  /// No description provided for @plansCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current assignment'**
  String get plansCurrent;

  /// No description provided for @plansCatalog.
  ///
  /// In en, this message translates to:
  /// **'Available plan tiers'**
  String get plansCatalog;

  /// No description provided for @plansSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support to request a plan assignment, extension or change. Support will arrange an authorized admin update. Catalog prices are for reference.'**
  String get plansSupport;

  /// No description provided for @plansNoTrial.
  ///
  /// In en, this message translates to:
  /// **'There is no automatic free trial or grace period. Plan access is checked by the server.'**
  String get plansNoTrial;

  /// No description provided for @plansActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get plansActive;

  /// No description provided for @plansUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get plansUnassigned;

  /// No description provided for @plansScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get plansScheduled;

  /// No description provided for @plansExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get plansExpired;

  /// No description provided for @plansUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Assignment unavailable'**
  String get plansUnavailable;

  /// No description provided for @plansCapacity.
  ///
  /// In en, this message translates to:
  /// **'Active customers: {count} / {limit}'**
  String plansCapacity(int count, int limit);

  /// No description provided for @plansSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup allows up to {limit} active customers without assigning a plan. This does not unlock paid features or customer discovery.'**
  String plansSetup(int limit);

  /// No description provided for @plansStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts: {time} IST'**
  String plansStarts(String time);

  /// No description provided for @plansEnds.
  ///
  /// In en, this message translates to:
  /// **'Access ends: {time} IST'**
  String plansEnds(String time);

  /// No description provided for @plansAtLimit.
  ///
  /// In en, this message translates to:
  /// **'The active customer limit has been reached or exceeded. Additions and reactivations are blocked until below the limit.'**
  String get plansAtLimit;

  /// No description provided for @plansGrowthBlocked.
  ///
  /// In en, this message translates to:
  /// **'Customer additions and reactivations are currently blocked. Refresh or contact support.'**
  String get plansGrowthBlocked;

  /// No description provided for @plansRetained.
  ///
  /// In en, this message translates to:
  /// **'Your existing customers and history are retained. Downgrading does not automatically delete or deactivate customers; permitted existing-customer business continues under the assigned tier.'**
  String get plansRetained;

  /// No description provided for @plansExpiryRules.
  ///
  /// In en, this message translates to:
  /// **'After expiry, history, payment recording, claim decisions and normally permitted completion or cancellation of existing orders remain. New orders, Quick Sales, subscriptions, generation and customer additions or reactivations are blocked until renewal.'**
  String get plansExpiryRules;

  /// No description provided for @plansAssignedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Paid features in the current assignment'**
  String get plansAssignedFeatures;

  /// No description provided for @plansIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get plansIncluded;

  /// No description provided for @plansLocked.
  ///
  /// In en, this message translates to:
  /// **'Not available in this assignment'**
  String get plansLocked;

  /// No description provided for @plansFeatureNotice.
  ///
  /// In en, this message translates to:
  /// **'Catalog features describe each tier. The server controls current access; saved information cannot grant features. Expiry exceptions for existing records and eligible settlement still apply.'**
  String get plansFeatureNotice;

  /// No description provided for @plansBasicReports.
  ///
  /// In en, this message translates to:
  /// **'Basic report summaries'**
  String get plansBasicReports;

  /// No description provided for @plansOrders.
  ///
  /// In en, this message translates to:
  /// **'Basic order management'**
  String get plansOrders;

  /// No description provided for @plansDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery management and holidays'**
  String get plansDelivery;

  /// No description provided for @plansAutoAccept.
  ///
  /// In en, this message translates to:
  /// **'Automatic subscription approval'**
  String get plansAutoAccept;

  /// No description provided for @plansStock.
  ///
  /// In en, this message translates to:
  /// **'Stock management'**
  String get plansStock;

  /// No description provided for @plansStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Low-stock alerts'**
  String get plansStockAlerts;

  /// No description provided for @plansAdvancedReports.
  ///
  /// In en, this message translates to:
  /// **'Daily/product reports and CSV export'**
  String get plansAdvancedReports;

  /// No description provided for @plansAdditionalFeature.
  ///
  /// In en, this message translates to:
  /// **'Additional catalog feature'**
  String get plansAdditionalFeature;

  /// No description provided for @plansSavedCurrent.
  ///
  /// In en, this message translates to:
  /// **'Showing saved assignment information. Refresh for current status, limits and access.'**
  String get plansSavedCurrent;

  /// No description provided for @plansSavedCatalog.
  ///
  /// In en, this message translates to:
  /// **'Showing saved catalog information. Refresh for current prices and features.'**
  String get plansSavedCatalog;

  /// No description provided for @plansCacheUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not save plan information for offline viewing.'**
  String get plansCacheUnavailable;

  /// No description provided for @plansCurrentMissing.
  ///
  /// In en, this message translates to:
  /// **'Current assignment information is unavailable. Connect and refresh.'**
  String get plansCurrentMissing;

  /// No description provided for @plansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active catalog plans are available. Contact support.'**
  String get plansEmpty;

  /// No description provided for @plansCatalogLimit.
  ///
  /// In en, this message translates to:
  /// **'Active customer limit: {limit}'**
  String plansCatalogLimit(int limit);

  /// No description provided for @plansPriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reference price unavailable. Contact support.'**
  String get plansPriceUnavailable;

  /// No description provided for @plansMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get plansMonthly;

  /// No description provided for @plansHalfYearly.
  ///
  /// In en, this message translates to:
  /// **'Half-yearly'**
  String get plansHalfYearly;

  /// No description provided for @plansYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get plansYearly;

  /// No description provided for @plansCatalogPrice.
  ///
  /// In en, this message translates to:
  /// **'{duration}: {price}'**
  String plansCatalogPrice(String duration, String price);
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
