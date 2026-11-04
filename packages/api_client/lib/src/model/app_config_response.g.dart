// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfigResponse _$AppConfigResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AppConfigResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['minVersionAndroid', 'flags'],
        );
        final val = AppConfigResponse(
          minVersionAndroid:
              $checkedConvert('minVersionAndroid', (v) => v as String),
          flags:
              $checkedConvert('flags', (v) => Map<String, bool>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AppConfigResponseToJson(AppConfigResponse instance) =>
    <String, dynamic>{
      'minVersionAndroid': instance.minVersionAndroid,
      'flags': instance.flags,
    };
