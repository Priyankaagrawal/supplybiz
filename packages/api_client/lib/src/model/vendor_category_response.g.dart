// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_category_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorCategoryResponse _$VendorCategoryResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorCategoryResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'code', 'name', 'icon'],
        );
        final val = VendorCategoryResponse(
          id: $checkedConvert('id', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          icon: $checkedConvert('icon', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorCategoryResponseToJson(
        VendorCategoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'icon': instance.icon,
    };
