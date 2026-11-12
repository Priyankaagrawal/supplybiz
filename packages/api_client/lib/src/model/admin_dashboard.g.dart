// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDashboard _$AdminDashboardFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminDashboard',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'serverTime',
            'vendorsTotal',
            'vendorsSuspended',
            'kycPending',
            'kycVerified',
            'customersTotal',
            'customersBlocked',
            'ordersTotal',
            'ordersDelivered',
            'ordersFailed',
            'recordedGmvPaise',
            'gmvScope',
            'planAssignmentsTotal',
            'planRevenueStatus'
          ],
        );
        final val = AdminDashboard(
          serverTime:
              $checkedConvert('serverTime', (v) => DateTime.parse(v as String)),
          vendorsTotal:
              $checkedConvert('vendorsTotal', (v) => (v as num).toInt()),
          vendorsSuspended:
              $checkedConvert('vendorsSuspended', (v) => (v as num).toInt()),
          kycPending: $checkedConvert('kycPending', (v) => (v as num).toInt()),
          kycVerified:
              $checkedConvert('kycVerified', (v) => (v as num).toInt()),
          customersTotal:
              $checkedConvert('customersTotal', (v) => (v as num).toInt()),
          customersBlocked:
              $checkedConvert('customersBlocked', (v) => (v as num).toInt()),
          ordersTotal:
              $checkedConvert('ordersTotal', (v) => (v as num).toInt()),
          ordersDelivered:
              $checkedConvert('ordersDelivered', (v) => (v as num).toInt()),
          ordersFailed:
              $checkedConvert('ordersFailed', (v) => (v as num).toInt()),
          recordedGmvPaise:
              $checkedConvert('recordedGmvPaise', (v) => v as String),
          gmvScope: $checkedConvert('gmvScope',
              (v) => $enumDecode(_$AdminDashboardGmvScopeEnumEnumMap, v)),
          planAssignmentsTotal: $checkedConvert(
              'planAssignmentsTotal', (v) => (v as num).toInt()),
          planRevenueStatus: $checkedConvert(
              'planRevenueStatus',
              (v) =>
                  $enumDecode(_$AdminDashboardPlanRevenueStatusEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AdminDashboardToJson(AdminDashboard instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime.toIso8601String(),
      'vendorsTotal': instance.vendorsTotal,
      'vendorsSuspended': instance.vendorsSuspended,
      'kycPending': instance.kycPending,
      'kycVerified': instance.kycVerified,
      'customersTotal': instance.customersTotal,
      'customersBlocked': instance.customersBlocked,
      'ordersTotal': instance.ordersTotal,
      'ordersDelivered': instance.ordersDelivered,
      'ordersFailed': instance.ordersFailed,
      'recordedGmvPaise': instance.recordedGmvPaise,
      'gmvScope': _$AdminDashboardGmvScopeEnumEnumMap[instance.gmvScope]!,
      'planAssignmentsTotal': instance.planAssignmentsTotal,
      'planRevenueStatus': _$AdminDashboardPlanRevenueStatusEnumEnumMap[
          instance.planRevenueStatus]!,
    };

const _$AdminDashboardGmvScopeEnumEnumMap = {
  AdminDashboardGmvScopeEnum.DELIVERED_ORDERS_ONLY: 'DELIVERED_ORDERS_ONLY',
};

const _$AdminDashboardPlanRevenueStatusEnumEnumMap = {
  AdminDashboardPlanRevenueStatusEnum.UNAVAILABLE: 'UNAVAILABLE',
};
