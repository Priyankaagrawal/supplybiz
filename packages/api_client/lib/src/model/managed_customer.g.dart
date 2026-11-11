// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedCustomer _$ManagedCustomerFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ManagedCustomer',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'name', 'mobile', 'status', 'updatedAt'],
        );
        final val = ManagedCustomer(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String?),
          mobile: $checkedConvert('mobile', (v) => v as String),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$ManagedCustomerStatusEnumEnumMap, v)),
          updatedAt:
              $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ManagedCustomerToJson(ManagedCustomer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'mobile': instance.mobile,
      'status': _$ManagedCustomerStatusEnumEnumMap[instance.status]!,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ManagedCustomerStatusEnumEnumMap = {
  ManagedCustomerStatusEnum.ACTIVE: 'ACTIVE',
  ManagedCustomerStatusEnum.BLOCKED: 'BLOCKED',
  ManagedCustomerStatusEnum.DELETED: 'DELETED',
};
