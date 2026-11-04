// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_session_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminSessionResponse _$AdminSessionResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminSessionResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['sessionToken', 'csrfToken'],
        );
        final val = AdminSessionResponse(
          sessionToken: $checkedConvert('sessionToken', (v) => v as String),
          csrfToken: $checkedConvert('csrfToken', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$AdminSessionResponseToJson(
        AdminSessionResponse instance) =>
    <String, dynamic>{
      'sessionToken': instance.sessionToken,
      'csrfToken': instance.csrfToken,
    };
