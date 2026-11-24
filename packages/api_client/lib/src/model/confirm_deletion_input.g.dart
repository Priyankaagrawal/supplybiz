// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_deletion_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfirmDeletionInput _$ConfirmDeletionInputFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ConfirmDeletionInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['code', 'acknowledgeReceivables'],
        );
        final val = ConfirmDeletionInput(
          code: $checkedConvert('code', (v) => v as String),
          acknowledgeReceivables:
              $checkedConvert('acknowledgeReceivables', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$ConfirmDeletionInputToJson(
        ConfirmDeletionInput instance) =>
    <String, dynamic>{
      'code': instance.code,
      'acknowledgeReceivables': instance.acknowledgeReceivables,
    };
