// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_deleted.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressDeleted _$AddressDeletedFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AddressDeleted',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'deleted'],
        );
        final val = AddressDeleted(
          id: $checkedConvert('id', (v) => v as String),
          deleted: $checkedConvert('deleted', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$AddressDeletedToJson(AddressDeleted instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deleted': instance.deleted,
    };
