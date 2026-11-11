// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_mutation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationMutationResponse _$NotificationMutationResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'NotificationMutationResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['changed'],
        );
        final val = NotificationMutationResponse(
          changed: $checkedConvert('changed', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$NotificationMutationResponseToJson(
        NotificationMutationResponse instance) =>
    <String, dynamic>{
      'changed': instance.changed,
    };
