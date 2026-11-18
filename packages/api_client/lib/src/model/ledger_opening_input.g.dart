// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_opening_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedgerOpeningInput _$LedgerOpeningInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LedgerOpeningInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['type', 'amountPaise', 'note'],
        );
        final val = LedgerOpeningInput(
          type: $checkedConvert('type',
              (v) => $enumDecode(_$LedgerOpeningInputTypeEnumEnumMap, v)),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          note: $checkedConvert('note', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$LedgerOpeningInputToJson(LedgerOpeningInput instance) =>
    <String, dynamic>{
      'type': _$LedgerOpeningInputTypeEnumEnumMap[instance.type]!,
      'amountPaise': instance.amountPaise,
      'note': instance.note,
    };

const _$LedgerOpeningInputTypeEnumEnumMap = {
  LedgerOpeningInputTypeEnum.DEBIT: 'DEBIT',
  LedgerOpeningInputTypeEnum.CREDIT: 'CREDIT',
};
