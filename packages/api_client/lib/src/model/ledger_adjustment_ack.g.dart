// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_adjustment_ack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedgerAdjustmentAck _$LedgerAdjustmentAckFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LedgerAdjustmentAck',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id'],
        );
        final val = LedgerAdjustmentAck(
          id: $checkedConvert('id', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$LedgerAdjustmentAckToJson(
        LedgerAdjustmentAck instance) =>
    <String, dynamic>{
      'id': instance.id,
    };
