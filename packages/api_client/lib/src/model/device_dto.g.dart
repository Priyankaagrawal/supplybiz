// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceDto _$DeviceDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
      'DeviceDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['platform'],
        );
        final val = DeviceDto(
          platform: $checkedConvert('platform',
              (v) => $enumDecode(_$DeviceDtoPlatformEnumEnumMap, v)),
          appVersion: $checkedConvert('appVersion', (v) => v as String?),
          osVersion: $checkedConvert('osVersion', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$DeviceDtoToJson(DeviceDto instance) => <String, dynamic>{
      'platform': _$DeviceDtoPlatformEnumEnumMap[instance.platform]!,
      if (instance.appVersion case final value?) 'appVersion': value,
      if (instance.osVersion case final value?) 'osVersion': value,
    };

const _$DeviceDtoPlatformEnumEnumMap = {
  DeviceDtoPlatformEnum.ANDROID: 'ANDROID',
  DeviceDtoPlatformEnum.IOS: 'IOS',
  DeviceDtoPlatformEnum.WEB: 'WEB',
};
