// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_pause.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPause _$SubscriptionPauseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionPause',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = SubscriptionPause(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          fromDate: $checkedConvert('fromDate',
              (v) => v == null ? null : DateTime.parse(v as String)),
          toDate: $checkedConvert(
              'toDate', (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionPauseToJson(SubscriptionPause instance) =>
    <String, dynamic>{
      'version': instance.version,
      if (instance.fromDate?.toIso8601String() case final value?)
        'fromDate': value,
      if (instance.toDate?.toIso8601String() case final value?) 'toDate': value,
    };
