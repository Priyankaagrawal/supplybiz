// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletionReceipt _$DeletionReceiptFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeletionReceipt',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['requestId', 'requestedAt', 'eraseBy', 'status'],
        );
        final val = DeletionReceipt(
          requestId: $checkedConvert('requestId', (v) => v as String),
          requestedAt: $checkedConvert('requestedAt', (v) => v as String),
          eraseBy: $checkedConvert('eraseBy', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$DeletionReceiptToJson(DeletionReceipt instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'requestedAt': instance.requestedAt,
      'eraseBy': instance.eraseBy,
      'status': instance.status,
    };
