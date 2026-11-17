// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'khata_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KhataVersion _$KhataVersionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KhataVersion',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = KhataVersion(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$KhataVersionToJson(KhataVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
    };
