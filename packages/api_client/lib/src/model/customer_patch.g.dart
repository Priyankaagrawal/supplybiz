// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerPatch _$CustomerPatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CustomerPatch',
      json,
      ($checkedConvert) {
        final val = CustomerPatch(
          name: $checkedConvert('name', (v) => v as String?),
          mobile: $checkedConvert('mobile', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          address: $checkedConvert('address', (v) => v as String?),
          preferredPayment: $checkedConvert(
              'preferredPayment',
              (v) => $enumDecodeNullable(
                  _$CustomerPatchPreferredPaymentEnumEnumMap, v)),
          status: $checkedConvert('status',
              (v) => $enumDecodeNullable(_$CustomerPatchStatusEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$CustomerPatchToJson(CustomerPatch instance) =>
    <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.mobile case final value?) 'mobile': value,
      if (instance.email case final value?) 'email': value,
      if (instance.address case final value?) 'address': value,
      if (_$CustomerPatchPreferredPaymentEnumEnumMap[instance.preferredPayment]
          case final value?)
        'preferredPayment': value,
      if (_$CustomerPatchStatusEnumEnumMap[instance.status] case final value?)
        'status': value,
    };

const _$CustomerPatchPreferredPaymentEnumEnumMap = {
  CustomerPatchPreferredPaymentEnum.CASH: 'CASH',
  CustomerPatchPreferredPaymentEnum.UPI: 'UPI',
  CustomerPatchPreferredPaymentEnum.BANK: 'BANK',
  CustomerPatchPreferredPaymentEnum.WALLET: 'WALLET',
};

const _$CustomerPatchStatusEnumEnumMap = {
  CustomerPatchStatusEnum.ACTIVE: 'ACTIVE',
  CustomerPatchStatusEnum.INACTIVE: 'INACTIVE',
};
