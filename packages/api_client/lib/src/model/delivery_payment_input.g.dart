// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_payment_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryPaymentInput _$DeliveryPaymentInputFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'DeliveryPaymentInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['collected'],
        );
        final val = DeliveryPaymentInput(
          collected: $checkedConvert('collected', (v) => v as bool),
          method: $checkedConvert(
              'method',
              (v) => $enumDecodeNullable(
                  _$DeliveryPaymentInputMethodEnumEnumMap, v)),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$DeliveryPaymentInputToJson(
        DeliveryPaymentInput instance) =>
    <String, dynamic>{
      'collected': instance.collected,
      if (_$DeliveryPaymentInputMethodEnumEnumMap[instance.method]
          case final value?)
        'method': value,
      if (instance.amountPaise case final value?) 'amountPaise': value,
    };

const _$DeliveryPaymentInputMethodEnumEnumMap = {
  DeliveryPaymentInputMethodEnum.CASH: 'CASH',
  DeliveryPaymentInputMethodEnum.UPI: 'UPI',
  DeliveryPaymentInputMethodEnum.BANK: 'BANK',
  DeliveryPaymentInputMethodEnum.WALLET: 'WALLET',
};
