// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReorderLine _$ReorderLineFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ReorderLine',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['product', 'qty'],
        );
        final val = ReorderLine(
          product: $checkedConvert('product',
              (v) => ProductResponse.fromJson(v as Map<String, dynamic>)),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReorderLineToJson(ReorderLine instance) =>
    <String, dynamic>{
      'product': instance.product.toJson(),
      'qty': instance.qty,
    };
