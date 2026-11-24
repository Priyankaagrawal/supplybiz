// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_hold_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivacyHoldInput _$PrivacyHoldInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PrivacyHoldInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['action', 'expectedVersion', 'reason'],
        );
        final val = PrivacyHoldInput(
          action: $checkedConvert('action',
              (v) => $enumDecode(_$PrivacyHoldInputActionEnumEnumMap, v)),
          expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PrivacyHoldInputToJson(PrivacyHoldInput instance) =>
    <String, dynamic>{
      'action': _$PrivacyHoldInputActionEnumEnumMap[instance.action]!,
      'expectedVersion': instance.expectedVersion,
      'reason': instance.reason,
    };

const _$PrivacyHoldInputActionEnumEnumMap = {
  PrivacyHoldInputActionEnum.HOLD: 'HOLD',
  PrivacyHoldInputActionEnum.RELEASE: 'RELEASE',
};
