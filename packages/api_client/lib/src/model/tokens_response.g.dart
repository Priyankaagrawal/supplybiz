// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tokens_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokensResponse _$TokensResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TokensResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'accessToken',
            'refreshToken',
            'expiresInSec',
            'user'
          ],
        );
        final val = TokensResponse(
          accessToken: $checkedConvert('accessToken', (v) => v as String),
          refreshToken: $checkedConvert('refreshToken', (v) => v as String),
          expiresInSec:
              $checkedConvert('expiresInSec', (v) => (v as num).toInt()),
          user: $checkedConvert(
              'user', (v) => MeResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$TokensResponseToJson(TokensResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresInSec': instance.expiresInSec,
      'user': instance.user.toJson(),
    };
