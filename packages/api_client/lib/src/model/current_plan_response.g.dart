// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_plan_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentPlanResponse _$CurrentPlanResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CurrentPlanResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'assignment',
            'status',
            'customerLimit',
            'activeCustomers',
            'canAddCustomer',
            'features'
          ],
        );
        final val = CurrentPlanResponse(
          assignment: $checkedConvert(
              'assignment',
              (v) => v == null
                  ? null
                  : VendorAssignmentResponse.fromJson(
                      v as Map<String, dynamic>)),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$CurrentPlanResponseStatusEnumEnumMap, v)),
          customerLimit:
              $checkedConvert('customerLimit', (v) => (v as num).toInt()),
          activeCustomers:
              $checkedConvert('activeCustomers', (v) => (v as num).toInt()),
          canAddCustomer: $checkedConvert('canAddCustomer', (v) => v as bool),
          features: $checkedConvert('features',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$CurrentPlanResponseToJson(
        CurrentPlanResponse instance) =>
    <String, dynamic>{
      'assignment': instance.assignment?.toJson(),
      'status': _$CurrentPlanResponseStatusEnumEnumMap[instance.status]!,
      'customerLimit': instance.customerLimit,
      'activeCustomers': instance.activeCustomers,
      'canAddCustomer': instance.canAddCustomer,
      'features': instance.features,
    };

const _$CurrentPlanResponseStatusEnumEnumMap = {
  CurrentPlanResponseStatusEnum.UNASSIGNED: 'UNASSIGNED',
  CurrentPlanResponseStatusEnum.SCHEDULED: 'SCHEDULED',
  CurrentPlanResponseStatusEnum.ACTIVE: 'ACTIVE',
  CurrentPlanResponseStatusEnum.EXPIRED: 'EXPIRED',
  CurrentPlanResponseStatusEnum.UNAVAILABLE: 'UNAVAILABLE',
};
