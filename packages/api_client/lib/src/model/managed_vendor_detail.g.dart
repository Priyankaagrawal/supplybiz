// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_vendor_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedVendorDetail _$ManagedVendorDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ManagedVendorDetail',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'businessName',
            'account',
            'category',
            'city',
            'kycStatus',
            'isSuspended',
            'badges',
            'updatedAt',
            'planCode',
            'planStatus',
            'planStartsAt',
            'planEndsAt',
            'customerLimit'
          ],
        );
        final val = ManagedVendorDetail(
          id: $checkedConvert('id', (v) => v as String),
          businessName: $checkedConvert('businessName', (v) => v as String?),
          account: $checkedConvert('account',
              (v) => ManagedCustomer.fromJson(v as Map<String, dynamic>)),
          category: $checkedConvert('category', (v) => v as String),
          city: $checkedConvert('city', (v) => v as String?),
          kycStatus: $checkedConvert('kycStatus', (v) => v as String),
          isSuspended: $checkedConvert('isSuspended', (v) => v as bool),
          badges: $checkedConvert('badges',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          updatedAt:
              $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
          planCode: $checkedConvert('planCode', (v) => v as String?),
          planStatus: $checkedConvert(
              'planStatus',
              (v) =>
                  $enumDecode(_$ManagedVendorDetailPlanStatusEnumEnumMap, v)),
          planStartsAt: $checkedConvert('planStartsAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
          planEndsAt: $checkedConvert('planEndsAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
          customerLimit:
              $checkedConvert('customerLimit', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ManagedVendorDetailToJson(
        ManagedVendorDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessName': instance.businessName,
      'account': instance.account.toJson(),
      'category': instance.category,
      'city': instance.city,
      'kycStatus': instance.kycStatus,
      'isSuspended': instance.isSuspended,
      'badges': instance.badges,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'planCode': instance.planCode,
      'planStatus':
          _$ManagedVendorDetailPlanStatusEnumEnumMap[instance.planStatus]!,
      'planStartsAt': instance.planStartsAt?.toIso8601String(),
      'planEndsAt': instance.planEndsAt?.toIso8601String(),
      'customerLimit': instance.customerLimit,
    };

const _$ManagedVendorDetailPlanStatusEnumEnumMap = {
  ManagedVendorDetailPlanStatusEnum.UNASSIGNED: 'UNASSIGNED',
  ManagedVendorDetailPlanStatusEnum.ACTIVE: 'ACTIVE',
  ManagedVendorDetailPlanStatusEnum.EXPIRED: 'EXPIRED',
  ManagedVendorDetailPlanStatusEnum.SCHEDULED: 'SCHEDULED',
  ManagedVendorDetailPlanStatusEnum.UNAVAILABLE: 'UNAVAILABLE',
};
