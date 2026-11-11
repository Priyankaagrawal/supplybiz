// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extend_plan_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtendPlanInput _$ExtendPlanInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ExtendPlanInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['endsAt', 'reason'],
        );
        final val = ExtendPlanInput(
          endsAt: $checkedConvert('endsAt', (v) => DateTime.parse(v as String)),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ExtendPlanInputToJson(ExtendPlanInput instance) =>
    <String, dynamic>{
      'endsAt': instance.endsAt.toIso8601String(),
      'reason': instance.reason,
    };
