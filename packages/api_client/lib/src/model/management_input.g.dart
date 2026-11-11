// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'management_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagementInput _$ManagementInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ManagementInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['reason', 'expectedUpdatedAt'],
        );
        final val = ManagementInput(
          reason: $checkedConvert('reason', (v) => v as String),
          expectedUpdatedAt: $checkedConvert(
              'expectedUpdatedAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ManagementInputToJson(ManagementInput instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'expectedUpdatedAt': instance.expectedUpdatedAt.toIso8601String(),
    };
