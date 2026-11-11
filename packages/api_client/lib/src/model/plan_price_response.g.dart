// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_price_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanPriceResponse _$PlanPriceResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanPriceResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['duration', 'pricePaise'],
        );
        final val = PlanPriceResponse(
          duration: $checkedConvert('duration',
              (v) => $enumDecode(_$PlanPriceResponseDurationEnumEnumMap, v)),
          pricePaise: $checkedConvert('pricePaise', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanPriceResponseToJson(PlanPriceResponse instance) =>
    <String, dynamic>{
      'duration': _$PlanPriceResponseDurationEnumEnumMap[instance.duration]!,
      'pricePaise': instance.pricePaise,
    };

const _$PlanPriceResponseDurationEnumEnumMap = {
  PlanPriceResponseDurationEnum.MONTHLY: 'MONTHLY',
  PlanPriceResponseDurationEnum.HALF_YEARLY: 'HALF_YEARLY',
  PlanPriceResponseDurationEnum.YEARLY: 'YEARLY',
};
