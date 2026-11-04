// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorCategoryDto _$VendorCategoryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorCategoryDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['categoryId'],
        );
        final val = VendorCategoryDto(
          categoryId: $checkedConvert('categoryId', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorCategoryDtoToJson(VendorCategoryDto instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
    };
