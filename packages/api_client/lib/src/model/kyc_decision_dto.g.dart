// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_decision_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KycDecisionDto _$KycDecisionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KycDecisionDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['decision', 'reason'],
        );
        final val = KycDecisionDto(
          decision: $checkedConvert('decision',
              (v) => $enumDecode(_$KycDecisionDtoDecisionEnumEnumMap, v)),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$KycDecisionDtoToJson(KycDecisionDto instance) =>
    <String, dynamic>{
      'decision': _$KycDecisionDtoDecisionEnumEnumMap[instance.decision]!,
      'reason': instance.reason,
    };

const _$KycDecisionDtoDecisionEnumEnumMap = {
  KycDecisionDtoDecisionEnum.VERIFIED: 'VERIFIED',
  KycDecisionDtoDecisionEnum.REJECTED: 'REJECTED',
};
