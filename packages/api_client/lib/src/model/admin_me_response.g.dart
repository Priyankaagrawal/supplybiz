// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_me_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMeResponse _$AdminMeResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminMeResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'role', 'permissions'],
        );
        final val = AdminMeResponse(
          id: $checkedConvert('id', (v) => v as String),
          role: $checkedConvert('role', (v) => v as String),
          permissions: $checkedConvert('permissions',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$AdminMeResponseToJson(AdminMeResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'permissions': instance.permissions,
    };
