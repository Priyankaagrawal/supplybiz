// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_plan_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogPlanInput _$CatalogPlanInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CatalogPlanInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'name',
            'status',
            'isPopular',
            'expectedUpdatedAt',
            'reason',
            'prices'
          ],
        );
        final val = CatalogPlanInput(
          name: $checkedConvert('name', (v) => v as String),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$CatalogPlanInputStatusEnumEnumMap, v)),
          isPopular: $checkedConvert('isPopular', (v) => v as bool),
          expectedUpdatedAt: $checkedConvert(
              'expectedUpdatedAt', (v) => DateTime.parse(v as String)),
          reason: $checkedConvert('reason', (v) => v as String),
          prices: $checkedConvert(
              'prices',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      CatalogPriceInput.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$CatalogPlanInputToJson(CatalogPlanInput instance) =>
    <String, dynamic>{
      'name': instance.name,
      'status': _$CatalogPlanInputStatusEnumEnumMap[instance.status]!,
      'isPopular': instance.isPopular,
      'expectedUpdatedAt': instance.expectedUpdatedAt.toIso8601String(),
      'reason': instance.reason,
      'prices': instance.prices.map((e) => e.toJson()).toList(),
    };

const _$CatalogPlanInputStatusEnumEnumMap = {
  CatalogPlanInputStatusEnum.ACTIVE: 'ACTIVE',
  CatalogPlanInputStatusEnum.INACTIVE: 'INACTIVE',
};
