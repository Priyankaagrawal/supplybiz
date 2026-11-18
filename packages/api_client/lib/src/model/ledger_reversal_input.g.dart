// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_reversal_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedgerReversalInput _$LedgerReversalInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LedgerReversalInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['reason'],
        );
        final val = LedgerReversalInput(
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$LedgerReversalInputToJson(
        LedgerReversalInput instance) =>
    <String, dynamic>{
      'reason': instance.reason,
    };
