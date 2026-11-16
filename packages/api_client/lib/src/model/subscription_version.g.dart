// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionVersion _$SubscriptionVersionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionVersion',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = SubscriptionVersion(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionVersionToJson(
        SubscriptionVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
    };
