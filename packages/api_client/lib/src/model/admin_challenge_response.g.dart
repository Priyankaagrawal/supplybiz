// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_challenge_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminChallengeResponse _$AdminChallengeResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminChallengeResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['challengeToken'],
        );
        final val = AdminChallengeResponse(
          challengeToken: $checkedConvert('challengeToken', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$AdminChallengeResponseToJson(
        AdminChallengeResponse instance) =>
    <String, dynamic>{
      'challengeToken': instance.challengeToken,
    };
