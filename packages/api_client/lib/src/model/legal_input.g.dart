// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegalInput _$LegalInputFromJson(Map<String, dynamic> json) => $checkedCreate(
      'LegalInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['expectedVersion', 'version', 'title', 'text'],
        );
        final val = LegalInput(
          expectedVersion:
              $checkedConvert('expectedVersion', (v) => v as String?),
          version: $checkedConvert('version', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          text: $checkedConvert('text', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$LegalInputToJson(LegalInput instance) =>
    <String, dynamic>{
      'expectedVersion': instance.expectedVersion,
      'version': instance.version,
      'title': instance.title,
      'text': instance.text,
    };
