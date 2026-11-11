// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_push_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DevicePushResponse _$DevicePushResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DevicePushResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['deviceId', 'pushEnabled'],
        );
        final val = DevicePushResponse(
          deviceId: $checkedConvert('deviceId', (v) => v as String),
          pushEnabled: $checkedConvert('pushEnabled', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$DevicePushResponseToJson(DevicePushResponse instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'pushEnabled': instance.pushEnabled,
    };
