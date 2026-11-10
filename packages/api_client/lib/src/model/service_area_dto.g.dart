// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_area_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAreaDto _$ServiceAreaDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ServiceAreaDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['serviceRadiusKm', 'pincodes'],
        );
        final val = ServiceAreaDto(
          serviceRadiusKm:
              $checkedConvert('serviceRadiusKm', (v) => (v as num?)?.toInt()),
          pincodes: $checkedConvert('pincodes',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ServiceAreaDtoToJson(ServiceAreaDto instance) =>
    <String, dynamic>{
      'serviceRadiusKm': instance.serviceRadiusKm,
      'pincodes': instance.pincodes,
    };
