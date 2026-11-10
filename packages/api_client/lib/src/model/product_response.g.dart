// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductResponse _$ProductResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProductResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'name',
            'productType',
            'milkType',
            'unitValue',
            'unitType',
            'sellingPricePaise',
            'subscriptionPricePaise',
            'stockQty',
            'moq',
            'description',
            'imageMediaId',
            'isActive',
            'version'
          ],
        );
        final val = ProductResponse(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          productType: $checkedConvert('productType', (v) => v as String),
          milkType: $checkedConvert('milkType', (v) => v as String?),
          unitValue: $checkedConvert('unitValue', (v) => v as num),
          unitType: $checkedConvert('unitType',
              (v) => $enumDecode(_$ProductResponseUnitTypeEnumEnumMap, v)),
          sellingPricePaise:
              $checkedConvert('sellingPricePaise', (v) => (v as num).toInt()),
          subscriptionPricePaise: $checkedConvert(
              'subscriptionPricePaise', (v) => (v as num?)?.toInt()),
          stockQty: $checkedConvert('stockQty', (v) => (v as num).toInt()),
          moq: $checkedConvert('moq', (v) => (v as num).toInt()),
          description: $checkedConvert('description', (v) => v as String),
          imageMediaId: $checkedConvert('imageMediaId', (v) => v as String?),
          isActive: $checkedConvert('isActive', (v) => v as bool),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProductResponseToJson(ProductResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'productType': instance.productType,
      'milkType': instance.milkType,
      'unitValue': instance.unitValue,
      'unitType': _$ProductResponseUnitTypeEnumEnumMap[instance.unitType]!,
      'sellingPricePaise': instance.sellingPricePaise,
      'subscriptionPricePaise': instance.subscriptionPricePaise,
      'stockQty': instance.stockQty,
      'moq': instance.moq,
      'description': instance.description,
      'imageMediaId': instance.imageMediaId,
      'isActive': instance.isActive,
      'version': instance.version,
    };

const _$ProductResponseUnitTypeEnumEnumMap = {
  ProductResponseUnitTypeEnum.ML: 'ML',
  ProductResponseUnitTypeEnum.L: 'L',
  ProductResponseUnitTypeEnum.G: 'G',
  ProductResponseUnitTypeEnum.KG: 'KG',
  ProductResponseUnitTypeEnum.PCS: 'PCS',
};
