// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_mutation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionMutation _$SubscriptionMutationFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionMutation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'version', 'status', 'effectiveFrom'],
        );
        final val = SubscriptionMutation(
          id: $checkedConvert('id', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          status: $checkedConvert('status', (v) => v as String),
          effectiveFrom: $checkedConvert(
              'effectiveFrom', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionMutationToJson(
        SubscriptionMutation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'status': instance.status,
      'effectiveFrom': instance.effectiveFrom.toIso8601String(),
    };
