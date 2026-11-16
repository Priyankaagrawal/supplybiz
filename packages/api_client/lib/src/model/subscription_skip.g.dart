// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_skip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionSkip _$SubscriptionSkipFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionSkip',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version', 'date'],
        );
        final val = SubscriptionSkip(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionSkipToJson(SubscriptionSkip instance) =>
    <String, dynamic>{
      'version': instance.version,
      'date': instance.date.toIso8601String(),
    };
