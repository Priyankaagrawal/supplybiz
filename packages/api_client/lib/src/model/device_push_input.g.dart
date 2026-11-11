// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_push_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DevicePushInput _$DevicePushInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DevicePushInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['pushEnabled'],
        );
        final val = DevicePushInput(
          pushToken: $checkedConvert('pushToken', (v) => v as String?),
          pushEnabled: $checkedConvert('pushEnabled', (v) => v as bool),
          appVersion: $checkedConvert('appVersion', (v) => v as String?),
          osVersion: $checkedConvert('osVersion', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$DevicePushInputToJson(DevicePushInput instance) =>
    <String, dynamic>{
      if (instance.pushToken case final value?) 'pushToken': value,
      'pushEnabled': instance.pushEnabled,
      if (instance.appVersion case final value?) 'appVersion': value,
      if (instance.osVersion case final value?) 'osVersion': value,
    };
