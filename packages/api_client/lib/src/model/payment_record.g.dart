// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentRecord _$PaymentRecordFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentRecord',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'vendorCustomerId',
            'orderId',
            'amountPaise',
            'method',
            'receivedOn',
            'note',
            'createdAt'
          ],
        );
        final val = PaymentRecord(
          id: $checkedConvert('id', (v) => v as String),
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String),
          orderId: $checkedConvert('orderId', (v) => v as String?),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          method: $checkedConvert('method', (v) => v as String),
          receivedOn:
              $checkedConvert('receivedOn', (v) => DateTime.parse(v as String)),
          note: $checkedConvert('note', (v) => v as String),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentRecordToJson(PaymentRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorCustomerId': instance.vendorCustomerId,
      'orderId': instance.orderId,
      'amountPaise': instance.amountPaise,
      'method': instance.method,
      'receivedOn': instance.receivedOn.toIso8601String(),
      'note': instance.note,
      'createdAt': instance.createdAt,
    };
