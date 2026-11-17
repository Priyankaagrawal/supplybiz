// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_mutation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimMutation _$ClaimMutationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ClaimMutation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'status', 'version'],
        );
        final val = ClaimMutation(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ClaimMutationToJson(ClaimMutation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'version': instance.version,
    };
