// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_payment_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordPaymentInput _$RecordPaymentInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RecordPaymentInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'vendorCustomerId',
            'amountPaise',
            'method',
            'receivedOn'
          ],
        );
        final val = RecordPaymentInput(
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          method: $checkedConvert('method',
              (v) => $enumDecode(_$RecordPaymentInputMethodEnumEnumMap, v)),
          receivedOn:
              $checkedConvert('receivedOn', (v) => DateTime.parse(v as String)),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$RecordPaymentInputToJson(RecordPaymentInput instance) =>
    <String, dynamic>{
      'vendorCustomerId': instance.vendorCustomerId,
      'amountPaise': instance.amountPaise,
      'method': _$RecordPaymentInputMethodEnumEnumMap[instance.method]!,
      'receivedOn': instance.receivedOn.toIso8601String(),
      if (instance.note case final value?) 'note': value,
    };

const _$RecordPaymentInputMethodEnumEnumMap = {
  RecordPaymentInputMethodEnum.CASH: 'CASH',
  RecordPaymentInputMethodEnum.UPI: 'UPI',
  RecordPaymentInputMethodEnum.BANK: 'BANK',
  RecordPaymentInputMethodEnum.WALLET: 'WALLET',
};
