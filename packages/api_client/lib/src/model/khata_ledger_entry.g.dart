// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'khata_ledger_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KhataLedgerEntry _$KhataLedgerEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KhataLedgerEntry',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'vendorCustomerId',
            'type',
            'amountPaise',
            'entryDate',
            'refType',
            'refId',
            'reversesEntryId',
            'note',
            'productSummary',
            'paymentStatus'
          ],
        );
        final val = KhataLedgerEntry(
          id: $checkedConvert('id', (v) => v as String),
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String),
          type: $checkedConvert(
              'type', (v) => $enumDecode(_$KhataLedgerEntryTypeEnumEnumMap, v)),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          entryDate:
              $checkedConvert('entryDate', (v) => DateTime.parse(v as String)),
          refType: $checkedConvert('refType', (v) => v as String),
          refId: $checkedConvert('refId', (v) => v as String),
          reversesEntryId:
              $checkedConvert('reversesEntryId', (v) => v as String?),
          note: $checkedConvert('note', (v) => v as String),
          productSummary:
              $checkedConvert('productSummary', (v) => v as String?),
          paymentStatus: $checkedConvert('paymentStatus', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$KhataLedgerEntryToJson(KhataLedgerEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorCustomerId': instance.vendorCustomerId,
      'type': _$KhataLedgerEntryTypeEnumEnumMap[instance.type]!,
      'amountPaise': instance.amountPaise,
      'entryDate': instance.entryDate.toIso8601String(),
      'refType': instance.refType,
      'refId': instance.refId,
      'reversesEntryId': instance.reversesEntryId,
      'note': instance.note,
      'productSummary': instance.productSummary,
      'paymentStatus': instance.paymentStatus,
    };

const _$KhataLedgerEntryTypeEnumEnumMap = {
  KhataLedgerEntryTypeEnum.DEBIT: 'DEBIT',
  KhataLedgerEntryTypeEnum.CREDIT: 'CREDIT',
};
