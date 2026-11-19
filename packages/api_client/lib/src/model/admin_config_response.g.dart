// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_config_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminConfigResponse _$AdminConfigResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminConfigResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['minVersionAndroid', 'flags', 'updatedAt'],
        );
        final val = AdminConfigResponse(
          minVersionAndroid:
              $checkedConvert('minVersionAndroid', (v) => v as String),
          flags:
              $checkedConvert('flags', (v) => Map<String, bool>.from(v as Map)),
          updatedAt: $checkedConvert('updatedAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AdminConfigResponseToJson(
        AdminConfigResponse instance) =>
    <String, dynamic>{
      'minVersionAndroid': instance.minVersionAndroid,
      'flags': instance.flags,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
