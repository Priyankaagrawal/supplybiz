// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_catalog_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanCatalogRow _$PlanCatalogRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanCatalogRow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'code',
            'name',
            'customerLimit',
            'features',
            'isPopular',
            'status',
            'prices'
          ],
        );
        final val = PlanCatalogRow(
          id: $checkedConvert('id', (v) => v as String),
          code: $checkedConvert(
              'code', (v) => $enumDecode(_$PlanCatalogRowCodeEnumEnumMap, v)),
          name: $checkedConvert('name', (v) => v as String),
          customerLimit:
              $checkedConvert('customerLimit', (v) => (v as num).toInt()),
          features: $checkedConvert('features',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          isPopular: $checkedConvert('isPopular', (v) => v as bool),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$PlanCatalogRowStatusEnumEnumMap, v)),
          prices: $checkedConvert(
              'prices',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      PlanPriceResponse.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanCatalogRowToJson(PlanCatalogRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': _$PlanCatalogRowCodeEnumEnumMap[instance.code]!,
      'name': instance.name,
      'customerLimit': instance.customerLimit,
      'features': instance.features,
      'isPopular': instance.isPopular,
      'status': _$PlanCatalogRowStatusEnumEnumMap[instance.status]!,
      'prices': instance.prices.map((e) => e.toJson()).toList(),
    };

const _$PlanCatalogRowCodeEnumEnumMap = {
  PlanCatalogRowCodeEnum.BASIC: 'BASIC',
  PlanCatalogRowCodeEnum.STANDARD: 'STANDARD',
  PlanCatalogRowCodeEnum.BUSINESS: 'BUSINESS',
  PlanCatalogRowCodeEnum.PREMIUM: 'PREMIUM',
};

const _$PlanCatalogRowStatusEnumEnumMap = {
  PlanCatalogRowStatusEnum.ACTIVE: 'ACTIVE',
  PlanCatalogRowStatusEnum.INACTIVE: 'INACTIVE',
};
