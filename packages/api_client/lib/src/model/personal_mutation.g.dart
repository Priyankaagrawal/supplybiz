// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_mutation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalMutation _$PersonalMutationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalMutation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'version', 'deleted'],
        );
        final val = PersonalMutation(
          id: $checkedConvert('id', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          deleted: $checkedConvert('deleted', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$PersonalMutationToJson(PersonalMutation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'deleted': instance.deleted,
    };
