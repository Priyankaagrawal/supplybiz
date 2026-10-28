// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_controller_get_version200_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionControllerGetVersion200Response
    _$VersionControllerGetVersion200ResponseFromJson(
            Map<String, dynamic> json) =>
        $checkedCreate(
          'VersionControllerGetVersion200Response',
          json,
          ($checkedConvert) {
            $checkKeys(
              json,
              requiredKeys: const ['service', 'version', 'nodeEnv'],
            );
            final val = VersionControllerGetVersion200Response(
              service: $checkedConvert('service', (v) => v as String),
              version: $checkedConvert('version', (v) => v as String),
              nodeEnv: $checkedConvert('nodeEnv', (v) => v as String),
              buildTime: $checkedConvert('buildTime', (v) => v as String?),
              gitSha: $checkedConvert('gitSha', (v) => v as String?),
            );
            return val;
          },
        );

Map<String, dynamic> _$VersionControllerGetVersion200ResponseToJson(
        VersionControllerGetVersion200Response instance) =>
    <String, dynamic>{
      'service': instance.service,
      'version': instance.version,
      'nodeEnv': instance.nodeEnv,
      if (instance.buildTime case final value?) 'buildTime': value,
      if (instance.gitSha case final value?) 'gitSha': value,
    };
