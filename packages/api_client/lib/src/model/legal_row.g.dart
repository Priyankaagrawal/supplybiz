// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegalRow _$LegalRowFromJson(Map<String, dynamic> json) => $checkedCreate(
      'LegalRow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'type',
            'version',
            'title',
            'text',
            'sha256',
            'publishedAt'
          ],
        );
        final val = LegalRow(
          type: $checkedConvert(
              'type', (v) => $enumDecode(_$LegalRowTypeEnumEnumMap, v)),
          version: $checkedConvert('version', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          text: $checkedConvert('text', (v) => v as String),
          sha256: $checkedConvert('sha256', (v) => v as String),
          publishedAt: $checkedConvert(
              'publishedAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$LegalRowToJson(LegalRow instance) => <String, dynamic>{
      'type': _$LegalRowTypeEnumEnumMap[instance.type]!,
      'version': instance.version,
      'title': instance.title,
      'text': instance.text,
      'sha256': instance.sha256,
      'publishedAt': instance.publishedAt.toIso8601String(),
    };

const _$LegalRowTypeEnumEnumMap = {
  LegalRowTypeEnum.TERMS: 'TERMS',
  LegalRowTypeEnum.PRIVACY: 'PRIVACY',
};
