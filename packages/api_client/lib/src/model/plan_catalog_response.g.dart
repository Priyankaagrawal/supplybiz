// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_catalog_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanCatalogResponse _$PlanCatalogResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanCatalogResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items'],
        );
        final val = PlanCatalogResponse(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => PlanCatalogRow.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanCatalogResponseToJson(
        PlanCatalogResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
