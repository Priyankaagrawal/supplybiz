// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductOptions _$ProductOptionsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProductOptions',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['productTypes'],
        );
        final val = ProductOptions(
          productTypes: $checkedConvert('productTypes',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProductOptionsToJson(ProductOptions instance) =>
    <String, dynamic>{
      'productTypes': instance.productTypes,
    };
