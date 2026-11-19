// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportProduct _$ReportProductFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportProduct',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'productId',
            'name',
            'unitValue',
            'unitType',
            'quantityPacks',
            'salesPaise'
          ],
        );
        final val = ReportProduct(
          productId: $checkedConvert('productId', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          unitValue: $checkedConvert('unitValue', (v) => v as String),
          unitType: $checkedConvert('unitType', (v) => v as String),
          quantityPacks: $checkedConvert('quantityPacks', (v) => v as String),
          salesPaise: $checkedConvert('salesPaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportProductToJson(ReportProduct instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'name': instance.name,
      'unitValue': instance.unitValue,
      'unitType': instance.unitType,
      'quantityPacks': instance.quantityPacks,
      'salesPaise': instance.salesPaise,
    };
