// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_deleted.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductDeleted _$ProductDeletedFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProductDeleted',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'deleted'],
        );
        final val = ProductDeleted(
          id: $checkedConvert('id', (v) => v as String),
          deleted: $checkedConvert('deleted', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProductDeletedToJson(ProductDeleted instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deleted': instance.deleted,
    };
