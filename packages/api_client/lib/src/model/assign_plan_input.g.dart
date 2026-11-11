// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assign_plan_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignPlanInput _$AssignPlanInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AssignPlanInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['endsAt', 'reason', 'planId', 'startsAt'],
        );
        final val = AssignPlanInput(
          endsAt: $checkedConvert('endsAt', (v) => DateTime.parse(v as String)),
          reason: $checkedConvert('reason', (v) => v as String),
          planId: $checkedConvert('planId', (v) => v as String),
          startsAt:
              $checkedConvert('startsAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AssignPlanInputToJson(AssignPlanInput instance) =>
    <String, dynamic>{
      'endsAt': instance.endsAt.toIso8601String(),
      'reason': instance.reason,
      'planId': instance.planId,
      'startsAt': instance.startsAt.toIso8601String(),
    };
