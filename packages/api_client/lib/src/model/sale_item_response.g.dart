// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItemResponse _$SaleItemResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SaleItemResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'productId',
            'name',
            'unitValue',
            'unitType',
            'qty',
            'ratePaise',
            'amountPaise'
          ],
        );
        final val = SaleItemResponse(
          productId: $checkedConvert('productId', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          unitValue: $checkedConvert('unitValue', (v) => v as String),
          unitType: $checkedConvert('unitType', (v) => v as String),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
          ratePaise: $checkedConvert('ratePaise', (v) => v as String),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$SaleItemResponseToJson(SaleItemResponse instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'name': instance.name,
      'unitValue': instance.unitValue,
      'unitType': instance.unitType,
      'qty': instance.qty,
      'ratePaise': instance.ratePaise,
      'amountPaise': instance.amountPaise,
    };
