import 'package:supplybiz_api_client/src/model/admin_challenge_response.dart';
import 'package:supplybiz_api_client/src/model/admin_enrollment_response.dart';
import 'package:supplybiz_api_client/src/model/admin_me_response.dart';
import 'package:supplybiz_api_client/src/model/admin_session_response.dart';
import 'package:supplybiz_api_client/src/model/app_config_response.dart';
import 'package:supplybiz_api_client/src/model/assign_plan_input.dart';
import 'package:supplybiz_api_client/src/model/assignment_response.dart';
import 'package:supplybiz_api_client/src/model/audit_page.dart';
import 'package:supplybiz_api_client/src/model/audit_row.dart';
import 'package:supplybiz_api_client/src/model/audit_snapshot.dart';
import 'package:supplybiz_api_client/src/model/catalog_plan_input.dart';
import 'package:supplybiz_api_client/src/model/catalog_price_input.dart';
import 'package:supplybiz_api_client/src/model/category_input.dart';
import 'package:supplybiz_api_client/src/model/category_list.dart';
import 'package:supplybiz_api_client/src/model/category_row.dart';
import 'package:supplybiz_api_client/src/model/consent_dto.dart';
import 'package:supplybiz_api_client/src/model/current_plan_response.dart';
import 'package:supplybiz_api_client/src/model/customer_input.dart';
import 'package:supplybiz_api_client/src/model/customer_list.dart';
import 'package:supplybiz_api_client/src/model/customer_patch.dart';
import 'package:supplybiz_api_client/src/model/customer_response.dart';
import 'package:supplybiz_api_client/src/model/device_dto.dart';
import 'package:supplybiz_api_client/src/model/device_push_input.dart';
import 'package:supplybiz_api_client/src/model/device_push_response.dart';
import 'package:supplybiz_api_client/src/model/extend_plan_input.dart';
import 'package:supplybiz_api_client/src/model/health_controller_get_live200_response.dart';
import 'package:supplybiz_api_client/src/model/inbox_item.dart';
import 'package:supplybiz_api_client/src/model/inbox_response.dart';
import 'package:supplybiz_api_client/src/model/kyc_decision_dto.dart';
import 'package:supplybiz_api_client/src/model/kyc_notice.dart';
import 'package:supplybiz_api_client/src/model/kyc_page.dart';
import 'package:supplybiz_api_client/src/model/kyc_response.dart';
import 'package:supplybiz_api_client/src/model/kyc_submission_dto.dart';
import 'package:supplybiz_api_client/src/model/link_decision_response.dart';
import 'package:supplybiz_api_client/src/model/link_request_list.dart';
import 'package:supplybiz_api_client/src/model/link_request_response.dart';
import 'package:supplybiz_api_client/src/model/login_dto.dart';
import 'package:supplybiz_api_client/src/model/me_response.dart';
import 'package:supplybiz_api_client/src/model/media_response.dart';
import 'package:supplybiz_api_client/src/model/notification_mutation_response.dart';
import 'package:supplybiz_api_client/src/model/notification_preferences.dart';
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
import 'package:supplybiz_api_client/src/model/read_notifications.dart';
import 'package:supplybiz_api_client/src/model/refresh_dto.dart';
import 'package:supplybiz_api_client/src/model/role_dto.dart';
import 'package:supplybiz_api_client/src/model/send_otp_dto.dart';
import 'package:supplybiz_api_client/src/model/send_otp_response.dart';
import 'package:supplybiz_api_client/src/model/service_area_dto.dart';
import 'package:supplybiz_api_client/src/model/stock_adjustment.dart';
import 'package:supplybiz_api_client/src/model/tokens_response.dart';
import 'package:supplybiz_api_client/src/model/totp_dto.dart';
import 'package:supplybiz_api_client/src/model/vendor_assignment_response.dart';
import 'package:supplybiz_api_client/src/model/vendor_business_dto.dart';
import 'package:supplybiz_api_client/src/model/vendor_category_dto.dart';
import 'package:supplybiz_api_client/src/model/vendor_category_response.dart';
import 'package:supplybiz_api_client/src/model/vendor_profile_response.dart';
import 'package:supplybiz_api_client/src/model/vendor_settings_response.dart';
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
    case 'AdminChallengeResponse':
      return AdminChallengeResponse.fromJson(value as Map<String, dynamic>)
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
    case 'ConsentDto':
      return ConsentDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CurrentPlanResponse':
      return CurrentPlanResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
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
    case 'DeviceDto':
      return DeviceDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DevicePushInput':
      return DevicePushInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DevicePushResponse':
      return DevicePushResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExtendPlanInput':
      return ExtendPlanInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthControllerGetLive200Response':
      return HealthControllerGetLive200Response.fromJson(
          value as Map<String, dynamic>) as ReturnType;
    case 'InboxItem':
      return InboxItem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'InboxResponse':
      return InboxResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'KycDecisionDto':
      return KycDecisionDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'KycNotice':
      return KycNotice.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KycPage':
      return KycPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KycResponse':
      return KycResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KycSubmissionDto':
      return KycSubmissionDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
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
    case 'ReadNotifications':
      return ReadNotifications.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RefreshDto':
      return RefreshDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RoleDto':
      return RoleDto.fromJson(value as Map<String, dynamic>) as ReturnType;
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
    case 'TokensResponse':
      return TokensResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TotpDto':
      return TotpDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VendorAssignmentResponse':
      return VendorAssignmentResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorBusinessDto':
      return VendorBusinessDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorCategoryDto':
      return VendorCategoryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorCategoryResponse':
      return VendorCategoryResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorProfileResponse':
      return VendorProfileResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VendorSettingsResponse':
      return VendorSettingsResponse.fromJson(value as Map<String, dynamic>)
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
