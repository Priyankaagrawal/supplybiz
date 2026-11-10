// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductPatch _$ProductPatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProductPatch',
      json,
      ($checkedConvert) {
        final val = ProductPatch(
          name: $checkedConvert('name', (v) => v as String?),
          productType: $checkedConvert('productType', (v) => v as String?),
          milkType: $checkedConvert('milkType',
              (v) => $enumDecodeNullable(_$ProductPatchMilkTypeEnumEnumMap, v)),
          unitValue: $checkedConvert('unitValue', (v) => v as num?),
          unitType: $checkedConvert('unitType',
              (v) => $enumDecodeNullable(_$ProductPatchUnitTypeEnumEnumMap, v)),
          sellingPricePaise:
              $checkedConvert('sellingPricePaise', (v) => (v as num?)?.toInt()),
          subscriptionPricePaise: $checkedConvert(
              'subscriptionPricePaise', (v) => (v as num?)?.toInt()),
          stockQty:
              $checkedConvert('stockQty', (v) => (v as num?)?.toInt() ?? 0),
          moq: $checkedConvert('moq', (v) => (v as num?)?.toInt() ?? 1),
          description:
              $checkedConvert('description', (v) => v as String? ?? ''),
          imageMediaId: $checkedConvert('imageMediaId', (v) => v as String?),
          isActive: $checkedConvert('isActive', (v) => v as bool? ?? true),
          stockReason: $checkedConvert('stockReason', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProductPatchToJson(ProductPatch instance) =>
    <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.productType case final value?) 'productType': value,
      if (_$ProductPatchMilkTypeEnumEnumMap[instance.milkType]
          case final value?)
        'milkType': value,
      if (instance.unitValue case final value?) 'unitValue': value,
      if (_$ProductPatchUnitTypeEnumEnumMap[instance.unitType]
          case final value?)
        'unitType': value,
      if (instance.sellingPricePaise case final value?)
        'sellingPricePaise': value,
      if (instance.subscriptionPricePaise case final value?)
        'subscriptionPricePaise': value,
      if (instance.stockQty case final value?) 'stockQty': value,
      if (instance.moq case final value?) 'moq': value,
      if (instance.description case final value?) 'description': value,
      if (instance.imageMediaId case final value?) 'imageMediaId': value,
      if (instance.isActive case final value?) 'isActive': value,
      if (instance.stockReason case final value?) 'stockReason': value,
    };

const _$ProductPatchMilkTypeEnumEnumMap = {
  ProductPatchMilkTypeEnum.COW: 'COW',
  ProductPatchMilkTypeEnum.BUFFALO: 'BUFFALO',
  ProductPatchMilkTypeEnum.TONED: 'TONED',
  ProductPatchMilkTypeEnum.DOUBLE_TONED: 'DOUBLE_TONED',
  ProductPatchMilkTypeEnum.FULL_CREAM: 'FULL_CREAM',
  ProductPatchMilkTypeEnum.OTHER: 'OTHER',
};

const _$ProductPatchUnitTypeEnumEnumMap = {
  ProductPatchUnitTypeEnum.ML: 'ML',
  ProductPatchUnitTypeEnum.L: 'L',
  ProductPatchUnitTypeEnum.G: 'G',
  ProductPatchUnitTypeEnum.KG: 'KG',
  ProductPatchUnitTypeEnum.PCS: 'PCS',
};
