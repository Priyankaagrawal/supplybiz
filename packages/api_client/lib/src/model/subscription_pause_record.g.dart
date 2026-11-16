// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_pause_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPauseRecord _$SubscriptionPauseRecordFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionPauseRecord',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['fromDate', 'toDate', 'resumedFrom'],
        );
        final val = SubscriptionPauseRecord(
          fromDate:
              $checkedConvert('fromDate', (v) => DateTime.parse(v as String)),
          toDate: $checkedConvert(
              'toDate', (v) => v == null ? null : DateTime.parse(v as String)),
          resumedFrom: $checkedConvert('resumedFrom',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionPauseRecordToJson(
        SubscriptionPauseRecord instance) =>
    <String, dynamic>{
      'fromDate': instance.fromDate.toIso8601String(),
      'toDate': instance.toDate?.toIso8601String(),
      'resumedFrom': instance.resumedFrom?.toIso8601String(),
    };
