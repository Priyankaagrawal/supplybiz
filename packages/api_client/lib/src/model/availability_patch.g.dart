// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailabilityPatch _$AvailabilityPatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AvailabilityPatch',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = AvailabilityPatch(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          acceptingToday: $checkedConvert('acceptingToday', (v) => v as bool?),
          deliveryPaused: $checkedConvert('deliveryPaused', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$AvailabilityPatchToJson(AvailabilityPatch instance) =>
    <String, dynamic>{
      'version': instance.version,
      if (instance.acceptingToday case final value?) 'acceptingToday': value,
      if (instance.deliveryPaused case final value?) 'deliveryPaused': value,
    };
