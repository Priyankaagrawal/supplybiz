// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_claim_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentClaimRecord _$PaymentClaimRecordFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentClaimRecord',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'vendorId',
            'vendorCustomerId',
            'amountPaise',
            'method',
            'upiTxnRef',
            'status',
            'version',
            'createdAt',
            'decidedAt',
            'rejectReason'
          ],
        );
        final val = PaymentClaimRecord(
          id: $checkedConvert('id', (v) => v as String),
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          method: $checkedConvert('method',
              (v) => $enumDecode(_$PaymentClaimRecordMethodEnumEnumMap, v)),
          upiTxnRef: $checkedConvert('upiTxnRef', (v) => v as String?),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$PaymentClaimRecordStatusEnumEnumMap, v)),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
          decidedAt: $checkedConvert('decidedAt', (v) => v as String?),
          rejectReason: $checkedConvert('rejectReason', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentClaimRecordToJson(PaymentClaimRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'vendorCustomerId': instance.vendorCustomerId,
      'amountPaise': instance.amountPaise,
      'method': _$PaymentClaimRecordMethodEnumEnumMap[instance.method]!,
      'upiTxnRef': instance.upiTxnRef,
      'status': _$PaymentClaimRecordStatusEnumEnumMap[instance.status]!,
      'version': instance.version,
      'createdAt': instance.createdAt,
      'decidedAt': instance.decidedAt,
      'rejectReason': instance.rejectReason,
    };

const _$PaymentClaimRecordMethodEnumEnumMap = {
  PaymentClaimRecordMethodEnum.UPI: 'UPI',
  PaymentClaimRecordMethodEnum.CASH: 'CASH',
};

const _$PaymentClaimRecordStatusEnumEnumMap = {
  PaymentClaimRecordStatusEnum.PENDING: 'PENDING',
  PaymentClaimRecordStatusEnum.CONFIRMED: 'CONFIRMED',
  PaymentClaimRecordStatusEnum.REJECTED: 'REJECTED',
};
