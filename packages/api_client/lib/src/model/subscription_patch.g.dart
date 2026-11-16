// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPatch _$SubscriptionPatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionPatch',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = SubscriptionPatch(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          qty: $checkedConvert('qty', (v) => (v as num?)?.toInt()),
          weekdays: $checkedConvert('weekdays',
              (v) => (v as List<dynamic>?)?.map((e) => e as num).toList()),
          timeSlot: $checkedConvert('timeSlot', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionPatchToJson(SubscriptionPatch instance) =>
    <String, dynamic>{
      'version': instance.version,
      if (instance.qty case final value?) 'qty': value,
      if (instance.weekdays case final value?) 'weekdays': value,
      if (instance.timeSlot case final value?) 'timeSlot': value,
    };
