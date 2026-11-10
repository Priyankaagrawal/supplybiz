// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductList _$ProductListFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ProductList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = ProductList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ProductResponse.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProductListToJson(ProductList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
