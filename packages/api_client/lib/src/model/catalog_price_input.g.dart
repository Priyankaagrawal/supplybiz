// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_price_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogPriceInput _$CatalogPriceInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CatalogPriceInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['duration', 'pricePaise'],
        );
        final val = CatalogPriceInput(
          duration: $checkedConvert('duration',
              (v) => $enumDecode(_$CatalogPriceInputDurationEnumEnumMap, v)),
          pricePaise: $checkedConvert('pricePaise', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$CatalogPriceInputToJson(CatalogPriceInput instance) =>
    <String, dynamic>{
      'duration': _$CatalogPriceInputDurationEnumEnumMap[instance.duration]!,
      'pricePaise': instance.pricePaise,
    };

const _$CatalogPriceInputDurationEnumEnumMap = {
  CatalogPriceInputDurationEnum.MONTHLY: 'MONTHLY',
  CatalogPriceInputDurationEnum.HALF_YEARLY: 'HALF_YEARLY',
  CatalogPriceInputDurationEnum.YEARLY: 'YEARLY',
};
