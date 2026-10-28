// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_controller_get_live200_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthControllerGetLive200Response _$HealthControllerGetLive200ResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'HealthControllerGetLive200Response',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['status', 'timestamp'],
        );
        final val = HealthControllerGetLive200Response(
          status: $checkedConvert('status', (v) => v as String),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$HealthControllerGetLive200ResponseToJson(
        HealthControllerGetLive200Response instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp.toIso8601String(),
    };
