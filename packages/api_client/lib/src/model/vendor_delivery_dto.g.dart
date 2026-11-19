// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_delivery_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorDeliveryDto _$VendorDeliveryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorDeliveryDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'version',
            'deliveryChargePaise',
            'minOrderPaise',
            'timeSlots',
            'acceptingToday',
            'sameDayCutoff'
          ],
        );
        final val = VendorDeliveryDto(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          deliveryChargePaise:
              $checkedConvert('deliveryChargePaise', (v) => (v as num).toInt()),
          minOrderPaise:
              $checkedConvert('minOrderPaise', (v) => (v as num).toInt()),
          timeSlots: $checkedConvert('timeSlots',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          acceptingToday: $checkedConvert('acceptingToday', (v) => v as bool),
          sameDayCutoff: $checkedConvert('sameDayCutoff', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorDeliveryDtoToJson(VendorDeliveryDto instance) =>
    <String, dynamic>{
      'version': instance.version,
      'deliveryChargePaise': instance.deliveryChargePaise,
      'minOrderPaise': instance.minOrderPaise,
      'timeSlots': instance.timeSlots,
      'acceptingToday': instance.acceptingToday,
      'sameDayCutoff': instance.sameDayCutoff,
    };
