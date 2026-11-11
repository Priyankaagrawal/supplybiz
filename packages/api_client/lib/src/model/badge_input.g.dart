// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BadgeInput _$BadgeInputFromJson(Map<String, dynamic> json) => $checkedCreate(
      'BadgeInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['reason', 'expectedUpdatedAt', 'badges'],
        );
        final val = BadgeInput(
          reason: $checkedConvert('reason', (v) => v as String),
          expectedUpdatedAt: $checkedConvert(
              'expectedUpdatedAt', (v) => DateTime.parse(v as String)),
          badges: $checkedConvert('badges',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$BadgeInputToJson(BadgeInput instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'expectedUpdatedAt': instance.expectedUpdatedAt.toIso8601String(),
      'badges': instance.badges,
    };
