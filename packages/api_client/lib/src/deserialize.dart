import 'package:supplybiz_api_client/src/model/address_deleted.dart';
import 'package:supplybiz_api_client/src/model/address_input.dart';
import 'package:supplybiz_api_client/src/model/address_list.dart';
import 'package:supplybiz_api_client/src/model/address_patch.dart';
import 'package:supplybiz_api_client/src/model/address_response.dart';
import 'package:supplybiz_api_client/src/model/admin_challenge_response.dart';
import 'package:supplybiz_api_client/src/model/admin_config_response.dart';
import 'package:supplybiz_api_client/src/model/admin_dashboard.dart';
import 'package:supplybiz_api_client/src/model/admin_enrollment_response.dart';
import 'package:supplybiz_api_client/src/model/admin_me_response.dart';
import 'package:supplybiz_api_client/src/model/admin_session_response.dart';
import 'package:supplybiz_api_client/src/model/app_config_response.dart';
import 'package:supplybiz_api_client/src/model/assign_plan_input.dart';
import 'package:supplybiz_api_client/src/model/assignment_response.dart';
import 'package:supplybiz_api_client/src/model/audit_page.dart';
import 'package:supplybiz_api_client/src/model/audit_row.dart';
import 'package:supplybiz_api_client/src/model/audit_snapshot.dart';
import 'package:supplybiz_api_client/src/model/availability_mutation.dart';
import 'package:supplybiz_api_client/src/model/availability_patch.dart';
import 'package:supplybiz_api_client/src/model/availability_response.dart';
import 'package:supplybiz_api_client/src/model/badge_input.dart';
import 'package:supplybiz_api_client/src/model/catalog_plan_input.dart';
import 'package:supplybiz_api_client/src/model/catalog_price_input.dart';
import 'package:supplybiz_api_client/src/model/category_input.dart';
import 'package:supplybiz_api_client/src/model/category_list.dart';
import 'package:supplybiz_api_client/src/model/category_row.dart';
import 'package:supplybiz_api_client/src/model/checkout_options.dart';
import 'package:supplybiz_api_client/src/model/claim_mutation.dart';
import 'package:supplybiz_api_client/src/model/claim_rejection.dart';
import 'package:supplybiz_api_client/src/model/complete_sale_input.dart';
import 'package:supplybiz_api_client/src/model/config_input.dart';
import 'package:supplybiz_api_client/src/model/consent_dto.dart';
import 'package:supplybiz_api_client/src/model/current_plan_response.dart';
import 'package:supplybiz_api_client/src/model/customer_home.dart';
import 'package:supplybiz_api_client/src/model/customer_input.dart';
import 'package:supplybiz_api_client/src/model/customer_list.dart';
import 'package:supplybiz_api_client/src/model/customer_patch.dart';
import 'package:supplybiz_api_client/src/model/customer_response.dart';
import 'package:supplybiz_api_client/src/model/customer_settlement_options.dart';
import 'package:supplybiz_api_client/src/model/customer_subscription_input.dart';
import 'package:supplybiz_api_client/src/model/delivery_counts.dart';
import 'package:supplybiz_api_client/src/model/delivery_impact.dart';
import 'package:supplybiz_api_client/src/model/delivery_list.dart';
import 'package:supplybiz_api_client/src/model/delivery_payment_input.dart';
import 'package:supplybiz_api_client/src/model/device_dto.dart';
import 'package:supplybiz_api_client/src/model/device_push_input.dart';
import 'package:supplybiz_api_client/src/model/device_push_response.dart';
import 'package:supplybiz_api_client/src/model/discovered_vendor.dart';
import 'package:supplybiz_api_client/src/model/discovery_page.dart';
import 'package:supplybiz_api_client/src/model/extend_plan_input.dart';
import 'package:supplybiz_api_client/src/model/faq_input.dart';
import 'package:supplybiz_api_client/src/model/faq_list.dart';
import 'package:supplybiz_api_client/src/model/faq_row.dart';
import 'package:supplybiz_api_client/src/model/favorite_result.dart';
import 'package:supplybiz_api_client/src/model/health_controller_get_live200_response.dart';
import 'package:supplybiz_api_client/src/model/holiday_deleted.dart';
import 'package:supplybiz_api_client/src/model/holiday_input.dart';
import 'package:supplybiz_api_client/src/model/holiday_list.dart';
import 'package:supplybiz_api_client/src/model/holiday_mutation.dart';
import 'package:supplybiz_api_client/src/model/holiday_record.dart';
import 'package:supplybiz_api_client/src/model/home_category.dart';
import 'package:supplybiz_api_client/src/model/home_delivery.dart';
import 'package:supplybiz_api_client/src/model/home_delivery_item.dart';
import 'package:supplybiz_api_client/src/model/inbox_item.dart';
import 'package:supplybiz_api_client/src/model/inbox_response.dart';
import 'package:supplybiz_api_client/src/model/khata_account.dart';
import 'package:supplybiz_api_client/src/model/khata_billing_account.dart';
import 'package:supplybiz_api_client/src/model/khata_ledger_entry.dart';
import 'package:supplybiz_api_client/src/model/khata_summary.dart';
import 'package:supplybiz_api_client/src/model/khata_vendor_entries.dart';
import 'package:supplybiz_api_client/src/model/khata_version.dart';
import 'package:supplybiz_api_client/src/model/kyc_decision_dto.dart';
import 'package:supplybiz_api_client/src/model/kyc_notice.dart';
import 'package:supplybiz_api_client/src/model/kyc_page.dart';
import 'package:supplybiz_api_client/src/model/kyc_response.dart';
import 'package:supplybiz_api_client/src/model/kyc_revision_dto.dart';
import 'package:supplybiz_api_client/src/model/kyc_submission_dto.dart';
import 'package:supplybiz_api_client/src/model/ledger_adjustment_ack.dart';
import 'package:supplybiz_api_client/src/model/ledger_opening_input.dart';
import 'package:supplybiz_api_client/src/model/ledger_reversal_input.dart';
import 'package:supplybiz_api_client/src/model/legal_input.dart';
import 'package:supplybiz_api_client/src/model/legal_list.dart';
import 'package:supplybiz_api_client/src/model/legal_row.dart';
import 'package:supplybiz_api_client/src/model/link_decision_response.dart';
import 'package:supplybiz_api_client/src/model/link_request_list.dart';
import 'package:supplybiz_api_client/src/model/link_request_response.dart';
import 'package:supplybiz_api_client/src/model/login_dto.dart';
import 'package:supplybiz_api_client/src/model/managed_customer.dart';
import 'package:supplybiz_api_client/src/model/managed_customer_list.dart';
import 'package:supplybiz_api_client/src/model/managed_vendor.dart';
import 'package:supplybiz_api_client/src/model/managed_vendor_detail.dart';
import 'package:supplybiz_api_client/src/model/managed_vendor_list.dart';
import 'package:supplybiz_api_client/src/model/management_input.dart';
import 'package:supplybiz_api_client/src/model/management_response.dart';
import 'package:supplybiz_api_client/src/model/me_response.dart';
import 'package:supplybiz_api_client/src/model/media_response.dart';
import 'package:supplybiz_api_client/src/model/notification_mutation_response.dart';
import 'package:supplybiz_api_client/src/model/notification_preferences.dart';
import 'package:supplybiz_api_client/src/model/order_cancel_input.dart';
import 'package:supplybiz_api_client/src/model/order_detail.dart';
import 'package:supplybiz_api_client/src/model/order_line_input.dart';
import 'package:supplybiz_api_client/src/model/order_list.dart';
import 'package:supplybiz_api_client/src/model/order_place_input.dart';
import 'package:supplybiz_api_client/src/model/order_priced_line.dart';
import 'package:supplybiz_api_client/src/model/order_problem.dart';
import 'package:supplybiz_api_client/src/model/order_quote.dart';
import 'package:supplybiz_api_client/src/model/order_quote_input.dart';
import 'package:supplybiz_api_client/src/model/order_reorder.dart';
import 'package:supplybiz_api_client/src/model/order_result.dart';
import 'package:supplybiz_api_client/src/model/order_status_event.dart';
import 'package:supplybiz_api_client/src/model/order_transition_input.dart';
import 'package:supplybiz_api_client/src/model/payment_claim_input.dart';
import 'package:supplybiz_api_client/src/model/payment_claim_list.dart';
import 'package:supplybiz_api_client/src/model/payment_claim_record.dart';
import 'package:supplybiz_api_client/src/model/payment_list.dart';
import 'package:supplybiz_api_client/src/model/payment_publication_ack.dart';
import 'package:supplybiz_api_client/src/model/payment_publication_input.dart';
import 'package:supplybiz_api_client/src/model/payment_record.dart';
import 'package:supplybiz_api_client/src/model/payment_summary.dart';
import 'package:supplybiz_api_client/src/model/personal_contact_input.dart';
import 'package:supplybiz_api_client/src/model/personal_contact_list.dart';
import 'package:supplybiz_api_client/src/model/personal_contact_patch.dart';
import 'package:supplybiz_api_client/src/model/personal_contact_record.dart';
import 'package:supplybiz_api_client/src/model/personal_entry_input.dart';
import 'package:supplybiz_api_client/src/model/personal_entry_list.dart';
import 'package:supplybiz_api_client/src/model/personal_entry_patch.dart';
import 'package:supplybiz_api_client/src/model/personal_entry_record.dart';
import 'package:supplybiz_api_client/src/model/personal_mutation.dart';
import 'package:supplybiz_api_client/src/model/plan_catalog_response.dart';
import 'package:supplybiz_api_client/src/model/plan_catalog_row.dart';
import 'package:supplybiz_api_client/src/model/plan_history_response.dart';
import 'package:supplybiz_api_client/src/model/plan_history_row.dart';
import 'package:supplybiz_api_client/src/model/plan_price_response.dart';
import 'package:supplybiz_api_client/src/model/plan_vendor_list.dart';
import 'package:supplybiz_api_client/src/model/plan_vendor_row.dart';
import 'package:supplybiz_api_client/src/model/product_deleted.dart';
import 'package:supplybiz_api_client/src/model/product_input.dart';
import 'package:supplybiz_api_client/src/model/product_list.dart';
import 'package:supplybiz_api_client/src/model/product_options.dart';
import 'package:supplybiz_api_client/src/model/product_patch.dart';
import 'package:supplybiz_api_client/src/model/product_response.dart';
import 'package:supplybiz_api_client/src/model/profile_input.dart';
import 'package:supplybiz_api_client/src/model/profile_response.dart';
import 'package:supplybiz_api_client/src/model/read_notifications.dart';
import 'package:supplybiz_api_client/src/model/record_payment_input.dart';
import 'package:supplybiz_api_client/src/model/refresh_dto.dart';
import 'package:supplybiz_api_client/src/model/reorder_line.dart';
import 'package:supplybiz_api_client/src/model/reorder_unavailable.dart';
import 'package:supplybiz_api_client/src/model/report_daily_sales.dart';
import 'package:supplybiz_api_client/src/model/report_export_created.dart';
import 'package:supplybiz_api_client/src/model/report_export_input.dart';
import 'package:supplybiz_api_client/src/model/report_export_status.dart';
import 'package:supplybiz_api_client/src/model/report_product.dart';
import 'package:supplybiz_api_client/src/model/report_products.dart';
import 'package:supplybiz_api_client/src/model/report_sales_bucket.dart';
import 'package:supplybiz_api_client/src/model/report_summary.dart';
import 'package:supplybiz_api_client/src/model/role_dto.dart';
import 'package:supplybiz_api_client/src/model/sale_item_response.dart';
import 'package:supplybiz_api_client/src/model/sale_line_input.dart';
import 'package:supplybiz_api_client/src/model/sale_list.dart';
import 'package:supplybiz_api_client/src/model/sale_response.dart';
import 'package:supplybiz_api_client/src/model/send_otp_dto.dart';
import 'package:supplybiz_api_client/src/model/send_otp_response.dart';
import 'package:supplybiz_api_client/src/model/service_area_dto.dart';
import 'package:supplybiz_api_client/src/model/stock_adjustment.dart';
import 'package:supplybiz_api_client/src/model/subscription_customer.dart';
import 'package:supplybiz_api_client/src/model/subscription_customer_list.dart';
import 'package:supplybiz_api_client/src/model/subscription_delivery.dart';
import 'package:supplybiz_api_client/src/model/subscription_list.dart';
import 'package:supplybiz_api_client/src/model/subscription_mutation.dart';
import 'package:supplybiz_api_client/src/model/subscription_patch.dart';
import 'package:supplybiz_api_client/src/model/subscription_pause.dart';
import 'package:supplybiz_api_client/src/model/subscription_pause_record.dart';
import 'package:supplybiz_api_client/src/model/subscription_plan.dart';
import 'package:supplybiz_api_client/src/model/subscription_plans.dart';
import 'package:supplybiz_api_client/src/model/subscription_record.dart';
import 'package:supplybiz_api_client/src/model/subscription_reject.dart';
import 'package:supplybiz_api_client/src/model/subscription_revision.dart';
import 'package:supplybiz_api_client/src/model/subscription_settings_patch.dart';
import 'package:supplybiz_api_client/src/model/subscription_settings_response.dart';
import 'package:supplybiz_api_client/src/model/subscription_settings_summary.dart';
import 'package:supplybiz_api_client/src/model/subscription_skip.dart';
import 'package:supplybiz_api_client/src/model/subscription_statement.dart';
import 'package:supplybiz_api_client/src/model/subscription_version.dart';
import 'package:supplybiz_api_client/src/model/tokens_response.dart';
import 'package:supplybiz_api_client/src/model/totp_dto.dart';
import 'package:supplybiz_api_client/src/model/vendor_about.dart';
import 'package:supplybiz_api_client/src/model/vendor_about_holidays_inner.dart';
import 'package:supplybiz_api_client/src/model/vendor_assignment_response.dart';
import 'package:supplybiz_api_client/src/model/vendor_business_dto.dart';
import 'package:supplybiz_api_client/src/model/vendor_business_edit_dto.dart';
import 'package:supplybiz_api_client/src/model/vendor_category_dto.dart';
import 'package:supplybiz_api_client/src/model/vendor_category_response.dart';
import 'package:supplybiz_api_client/src/model/vendor_collection.dart';
import 'package:supplybiz_api_client/src/model/vendor_collection_list.dart';
import 'package:supplybiz_api_client/src/model/vendor_dashboard.dart';
import 'package:supplybiz_api_client/src/model/vendor_delivery_dto.dart';
import 'package:supplybiz_api_client/src/model/vendor_khata_account.dart';
import 'package:supplybiz_api_client/src/model/vendor_khata_list.dart';
import 'package:supplybiz_api_client/src/model/vendor_payment_details.dart';
import 'package:supplybiz_api_client/src/model/vendor_profile_response.dart';
import 'package:supplybiz_api_client/src/model/vendor_settings_response.dart';
import 'package:supplybiz_api_client/src/model/vendor_subscription_input.dart';
import 'package:supplybiz_api_client/src/model/verify_otp_dto.dart';
import 'package:supplybiz_api_client/src/model/version_controller_get_version200_response.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType,
    {bool growable = true}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'AddressDeleted':
      return AddressDeleted.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AddressInput':
      return AddressInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AddressList':
      return AddressList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AddressPatch':
      return AddressPatch.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AddressResponse':
      return AddressResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminChallengeResponse':
      return AdminChallengeResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminConfigResponse':
      return AdminConfigResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminDashboard':
      return AdminDashboard.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminEnrollmentResponse':
      return AdminEnrollmentResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminMeResponse':
      return AdminMeResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminSessionResponse':
      return AdminSessionResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AppConfigResponse':
      return AppConfigResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AssignPlanInput':
      return AssignPlanInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AssignmentResponse':
      return AssignmentResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AuditPage':
      return AuditPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AuditRow':
      return AuditRow.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AuditSnapshot':
      return AuditSnapshot.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AvailabilityMutation':
      return AvailabilityMutation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AvailabilityPatch':
      return AvailabilityPatch.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AvailabilityResponse':
      return AvailabilityResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'BadgeInput':
      return BadgeInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CatalogPlanInput':
      return CatalogPlanInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CatalogPriceInput':
      return CatalogPriceInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CategoryInput':
      return CategoryInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CategoryList':
      return CategoryList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CategoryRow':
      return CategoryRow.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CheckoutOptions':
      return CheckoutOptions.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ClaimMutation':
      return ClaimMutation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ClaimRejection':
      return ClaimRejection.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CompleteSaleInput':
      return CompleteSaleInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ConfigInput':
      return ConfigInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ConsentDto':
      return ConsentDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CurrentPlanResponse':
      return CurrentPlanResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerHome':
      return CustomerHome.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CustomerInput':
      return CustomerInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerList':
      return CustomerList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CustomerPatch':
      return CustomerPatch.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerResponse':
      return CustomerResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerSettlementOptions':
      return CustomerSettlementOptions.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerSubscriptionInput':
      return CustomerSubscriptionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DeliveryCounts':
      return DeliveryCounts.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DeliveryImpact':
      return DeliveryImpact.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DeliveryList':
      return DeliveryList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DeliveryPaymentInput':
      return DeliveryPaymentInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DeviceDto':
      return DeviceDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DevicePushInput':
      return DevicePushInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DevicePushResponse':
      return DevicePushResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DiscoveredVendor':
      return DiscoveredVendor.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DiscoveryPage':
      return DiscoveryPage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExtendPlanInput':
      return ExtendPlanInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'FaqInput':
      return FaqInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'FaqList':
      return FaqList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'FaqRow':
      return FaqRow.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'FavoriteResult':
      return FavoriteResult.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthControllerGetLive200Response':
      return HealthControllerGetLive200Response.fromJson(
          value as Map<String, dynamic>) as ReturnType;
    case 'HolidayDeleted':
      return HolidayDeleted.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HolidayInput':
      return HolidayInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HolidayList':
      return HolidayList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HolidayMutation':
      return HolidayMutation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HolidayRecord':
      return HolidayRecord.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HomeCategory':
      return HomeCategory.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeDelivery':
      return HomeDelivery.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeDeliveryItem':
      return HomeDeliveryItem.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'InboxItem':
      return InboxItem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'InboxResponse':
      return InboxResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'KhataAccount':
      return KhataAccount.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KhataBillingAccount':
      return KhataBillingAccount.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'KhataLedgerEntry':
      return KhataLedgerEntry.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'KhataSummary':
      return KhataSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KhataVendorEntries':
      return KhataVendorEntries.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'KhataVersion':
      return KhataVersion.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KycDecisionDto':
      return KycDecisionDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'KycNotice':
      return KycNotice.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KycPage':
      return KycPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KycResponse':
      return KycResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KycRevisionDto':
      return KycRevisionDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'KycSubmissionDto':
      return KycSubmissionDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LedgerAdjustmentAck':
      return LedgerAdjustmentAck.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LedgerOpeningInput':
      return LedgerOpeningInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LedgerReversalInput':
      return LedgerReversalInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LegalInput':
      return LegalInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LegalList':
      return LegalList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LegalRow':
      return LegalRow.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LinkDecisionResponse':
      return LinkDecisionResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LinkRequestList':
      return LinkRequestList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LinkRequestResponse':
      return LinkRequestResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LoginDto':
      return LoginDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ManagedCustomer':
      return ManagedCustomer.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ManagedCustomerList':
      return ManagedCustomerList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ManagedVendor':
      return ManagedVendor.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ManagedVendorDetail':
      return ManagedVendorDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ManagedVendorList':
      return ManagedVendorList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ManagementInput':
      return ManagementInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ManagementResponse':
      return ManagementResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MeResponse':
      return MeResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MediaResponse':
      return MediaResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'NotificationMutationResponse':
      return NotificationMutationResponse.fromJson(
          value as Map<String, dynamic>) as ReturnType;
    case 'NotificationPreferences':
      return NotificationPreferences.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OrderCancelInput':
      return OrderCancelInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OrderDetail':
      return OrderDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'OrderLineInput':
      return OrderLineInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OrderList':
      return OrderList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'OrderPlaceInput':
      return OrderPlaceInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OrderPricedLine':
      return OrderPricedLine.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OrderProblem':
      return OrderProblem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'OrderQuote':
      return OrderQuote.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'OrderQuoteInput':
      return OrderQuoteInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OrderReorder':
      return OrderReorder.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'OrderResult':
      return OrderResult.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'OrderStatusEvent':
      return OrderStatusEvent.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OrderTransitionInput':
      return OrderTransitionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PaymentClaimInput':
      return PaymentClaimInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PaymentClaimList':
      return PaymentClaimList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PaymentClaimRecord':
      return PaymentClaimRecord.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PaymentList':
      return PaymentList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PaymentPublicationAck':
      return PaymentPublicationAck.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PaymentPublicationInput':
      return PaymentPublicationInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PaymentRecord':
      return PaymentRecord.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PaymentSummary':
      return PaymentSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalContactInput':
      return PersonalContactInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalContactList':
      return PersonalContactList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalContactPatch':
      return PersonalContactPatch.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalContactRecord':
      return PersonalContactRecord.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalEntryInput':
      return PersonalEntryInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalEntryList':
      return PersonalEntryList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalEntryPatch':
      return PersonalEntryPatch.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalEntryRecord':
      return PersonalEntryRecord.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalMutation':
      return PersonalMutation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanCatalogResponse':
      return PlanCatalogResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanCatalogRow':
      return PlanCatalogRow.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanHistoryResponse':
      return PlanHistoryResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanHistoryRow':
      return PlanHistoryRow.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanPriceResponse':
      return PlanPriceResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanVendorList':
      return PlanVendorList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanVendorRow':
      return PlanVendorRow.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProductDeleted':
      return ProductDeleted.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProductInput':
      return ProductInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProductList':
      return ProductList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProductOptions':
      return ProductOptions.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProductPatch':
      return ProductPatch.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProductResponse':
      return ProductResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProfileInput':
      return ProfileInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProfileResponse':
      return ProfileResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReadNotifications':
      return ReadNotifications.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecordPaymentInput':
      return RecordPaymentInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RefreshDto':
      return RefreshDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReorderLine':
      return ReorderLine.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReorderUnavailable':
      return ReorderUnavailable.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReportDailySales':
      return ReportDailySales.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReportExportCreated':
      return ReportExportCreated.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReportExportInput':
      return ReportExportInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReportExportStatus':
      return ReportExportStatus.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReportProduct':
      return ReportProduct.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReportProducts':
      return ReportProducts.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReportSalesBucket':
      return ReportSalesBucket.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReportSummary':
      return ReportSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RoleDto':
      return RoleDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SaleItemResponse':
      return SaleItemResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SaleLineInput':
      return SaleLineInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SaleList':
      return SaleList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SaleResponse':
      return SaleResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SendOtpDto':
      return SendOtpDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SendOtpResponse':
      return SendOtpResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ServiceAreaDto':
      return ServiceAreaDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StockAdjustment':
      return StockAdjustment.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionCustomer':
      return SubscriptionCustomer.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionCustomerList':
      return SubscriptionCustomerList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionDelivery':
      return SubscriptionDelivery.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionList':
      return SubscriptionList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionMutation':
      return SubscriptionMutation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionPatch':
      return SubscriptionPatch.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionPause':
      return SubscriptionPause.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionPauseRecord':
      return SubscriptionPauseRecord.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionPlan':
      return SubscriptionPlan.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionPlans':
      return SubscriptionPlans.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionRecord':
      return SubscriptionRecord.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionReject':
      return SubscriptionReject.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionRevision':
      return SubscriptionRevision.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionSettingsPatch':
      return SubscriptionSettingsPatch.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionSettingsResponse':
      return SubscriptionSettingsResponse.fromJson(
          value as Map<String, dynamic>) as ReturnType;
    case 'SubscriptionSettingsSummary':
      return SubscriptionSettingsSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionSkip':
      return SubscriptionSkip.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionStatement':
      return SubscriptionStatement.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionVersion':
      return SubscriptionVersion.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TokensResponse':
      return TokensResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TotpDto':
      return TotpDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VendorAbout':
      return VendorAbout.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VendorAboutHolidaysInner':
      return VendorAboutHolidaysInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorAssignmentResponse':
      return VendorAssignmentResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorBusinessDto':
      return VendorBusinessDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorBusinessEditDto':
      return VendorBusinessEditDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorCategoryDto':
      return VendorCategoryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorCategoryResponse':
      return VendorCategoryResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorCollection':
      return VendorCollection.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorCollectionList':
      return VendorCollectionList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorDashboard':
      return VendorDashboard.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorDeliveryDto':
      return VendorDeliveryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorKhataAccount':
      return VendorKhataAccount.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorKhataList':
      return VendorKhataList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorPaymentDetails':
      return VendorPaymentDetails.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorProfileResponse':
      return VendorProfileResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorSettingsResponse':
      return VendorSettingsResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorSubscriptionInput':
      return VendorSubscriptionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VerifyOtpDto':
      return VerifyOtpDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VersionControllerGetVersion200Response':
      return VersionControllerGetVersion200Response.fromJson(
          value as Map<String, dynamic>) as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
            .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(
                v, targetType,
                growable: growable))
            .toList(growable: growable) as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
            .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(
                v, targetType,
                growable: growable))
            .toSet() as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
          value.keys as Iterable<String>,
          value.values.map((dynamic v) => deserialize<BaseType, BaseType>(
              v, targetType,
              growable: growable)),
        ) as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
