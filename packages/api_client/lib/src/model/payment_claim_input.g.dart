// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_claim_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentClaimInput _$PaymentClaimInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentClaimInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['vendorCustomerId', 'amountPaise', 'method'],
        );
        final val = PaymentClaimInput(
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          method: $checkedConvert('method',
              (v) => $enumDecode(_$PaymentClaimInputMethodEnumEnumMap, v)),
          upiTxnRef: $checkedConvert('upiTxnRef', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentClaimInputToJson(PaymentClaimInput instance) =>
    <String, dynamic>{
      'vendorCustomerId': instance.vendorCustomerId,
      'amountPaise': instance.amountPaise,
      'method': _$PaymentClaimInputMethodEnumEnumMap[instance.method]!,
      if (instance.upiTxnRef case final value?) 'upiTxnRef': value,
    };

const _$PaymentClaimInputMethodEnumEnumMap = {
  PaymentClaimInputMethodEnum.UPI: 'UPI',
  PaymentClaimInputMethodEnum.CASH: 'CASH',
};
