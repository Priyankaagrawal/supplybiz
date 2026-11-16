// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_reject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionReject _$SubscriptionRejectFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionReject',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = SubscriptionReject(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          reason: $checkedConvert('reason', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionRejectToJson(SubscriptionReject instance) =>
    <String, dynamic>{
      'version': instance.version,
      if (instance.reason case final value?) 'reason': value,
    };
