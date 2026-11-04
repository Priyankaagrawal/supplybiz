// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsentDto _$ConsentDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ConsentDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['termsVersion', 'privacyVersion'],
        );
        final val = ConsentDto(
          termsVersion: $checkedConvert('termsVersion', (v) => v as String),
          privacyVersion: $checkedConvert('privacyVersion', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ConsentDtoToJson(ConsentDto instance) =>
    <String, dynamic>{
      'termsVersion': instance.termsVersion,
      'privacyVersion': instance.privacyVersion,
    };
