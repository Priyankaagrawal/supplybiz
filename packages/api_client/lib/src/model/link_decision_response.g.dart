// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_decision_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkDecisionResponse _$LinkDecisionResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'LinkDecisionResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'decision'],
        );
        final val = LinkDecisionResponse(
          id: $checkedConvert('id', (v) => v as String),
          decision: $checkedConvert('decision',
              (v) => $enumDecode(_$LinkDecisionResponseDecisionEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$LinkDecisionResponseToJson(
        LinkDecisionResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'decision': _$LinkDecisionResponseDecisionEnumEnumMap[instance.decision]!,
    };

const _$LinkDecisionResponseDecisionEnumEnumMap = {
  LinkDecisionResponseDecisionEnum.ACCEPTED: 'ACCEPTED',
  LinkDecisionResponseDecisionEnum.DECLINED: 'DECLINED',
};
