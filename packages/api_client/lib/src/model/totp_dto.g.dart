// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'totp_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotpDto _$TotpDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TotpDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['challengeToken', 'code'],
        );
        final val = TotpDto(
          challengeToken: $checkedConvert('challengeToken', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$TotpDtoToJson(TotpDto instance) => <String, dynamic>{
      'challengeToken': instance.challengeToken,
      'code': instance.code,
    };
