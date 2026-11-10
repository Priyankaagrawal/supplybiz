// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductInput _$ProductInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProductInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'name',
            'productType',
            'unitValue',
            'unitType',
            'sellingPricePaise'
          ],
        );
        final val = ProductInput(
          name: $checkedConvert('name', (v) => v as String),
          productType: $checkedConvert('productType', (v) => v as String),
          milkType: $checkedConvert('milkType',
              (v) => $enumDecodeNullable(_$ProductInputMilkTypeEnumEnumMap, v)),
          unitValue: $checkedConvert('unitValue', (v) => v as num),
          unitType: $checkedConvert('unitType',
              (v) => $enumDecode(_$ProductInputUnitTypeEnumEnumMap, v)),
          sellingPricePaise:
              $checkedConvert('sellingPricePaise', (v) => (v as num).toInt()),
          subscriptionPricePaise: $checkedConvert(
              'subscriptionPricePaise', (v) => (v as num?)?.toInt()),
          stockQty:
              $checkedConvert('stockQty', (v) => (v as num?)?.toInt() ?? 0),
          moq: $checkedConvert('moq', (v) => (v as num?)?.toInt() ?? 1),
          description:
              $checkedConvert('description', (v) => v as String? ?? ''),
          imageMediaId: $checkedConvert('imageMediaId', (v) => v as String?),
          isActive: $checkedConvert('isActive', (v) => v as bool? ?? true),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProductInputToJson(ProductInput instance) =>
    <String, dynamic>{
      'name': instance.name,
      'productType': instance.productType,
      if (_$ProductInputMilkTypeEnumEnumMap[instance.milkType]
          case final value?)
        'milkType': value,
      'unitValue': instance.unitValue,
      'unitType': _$ProductInputUnitTypeEnumEnumMap[instance.unitType]!,
      'sellingPricePaise': instance.sellingPricePaise,
      if (instance.subscriptionPricePaise case final value?)
        'subscriptionPricePaise': value,
      if (instance.stockQty case final value?) 'stockQty': value,
      if (instance.moq case final value?) 'moq': value,
      if (instance.description case final value?) 'description': value,
      if (instance.imageMediaId case final value?) 'imageMediaId': value,
      if (instance.isActive case final value?) 'isActive': value,
    };

const _$ProductInputMilkTypeEnumEnumMap = {
  ProductInputMilkTypeEnum.COW: 'COW',
  ProductInputMilkTypeEnum.BUFFALO: 'BUFFALO',
  ProductInputMilkTypeEnum.TONED: 'TONED',
  ProductInputMilkTypeEnum.DOUBLE_TONED: 'DOUBLE_TONED',
  ProductInputMilkTypeEnum.FULL_CREAM: 'FULL_CREAM',
  ProductInputMilkTypeEnum.OTHER: 'OTHER',
};

const _$ProductInputUnitTypeEnumEnumMap = {
  ProductInputUnitTypeEnum.ML: 'ML',
  ProductInputUnitTypeEnum.L: 'L',
  ProductInputUnitTypeEnum.G: 'G',
  ProductInputUnitTypeEnum.KG: 'KG',
  ProductInputUnitTypeEnum.PCS: 'PCS',
};
