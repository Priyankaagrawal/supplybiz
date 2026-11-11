// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerInput _$CustomerInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CustomerInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['name', 'mobile'],
        );
        final val = CustomerInput(
          name: $checkedConvert('name', (v) => v as String),
          mobile: $checkedConvert('mobile', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String?),
          address: $checkedConvert('address', (v) => v as String?),
          preferredPayment: $checkedConvert(
              'preferredPayment',
              (v) => $enumDecodeNullable(
                  _$CustomerInputPreferredPaymentEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$CustomerInputToJson(CustomerInput instance) =>
    <String, dynamic>{
      'name': instance.name,
      'mobile': instance.mobile,
      if (instance.email case final value?) 'email': value,
      if (instance.address case final value?) 'address': value,
      if (_$CustomerInputPreferredPaymentEnumEnumMap[instance.preferredPayment]
          case final value?)
        'preferredPayment': value,
    };

const _$CustomerInputPreferredPaymentEnumEnumMap = {
  CustomerInputPreferredPaymentEnum.CASH: 'CASH',
  CustomerInputPreferredPaymentEnum.UPI: 'UPI',
  CustomerInputPreferredPaymentEnum.BANK: 'BANK',
  CustomerInputPreferredPaymentEnum.WALLET: 'WALLET',
};
