// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_settings_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorSettingsResponse _$VendorSettingsResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorSettingsResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'serviceRadiusKm',
            'deliveryChargePaise',
            'minOrderPaise',
            'timeSlots',
            'autoAcceptSubscriptions',
            'acceptingToday',
            'deliveryPaused',
            'allowKhataOrders',
            'version'
          ],
        );
        final val = VendorSettingsResponse(
          serviceRadiusKm:
              $checkedConvert('serviceRadiusKm', (v) => (v as num?)?.toInt()),
          deliveryChargePaise:
              $checkedConvert('deliveryChargePaise', (v) => (v as num).toInt()),
          minOrderPaise:
              $checkedConvert('minOrderPaise', (v) => (v as num).toInt()),
          timeSlots: $checkedConvert('timeSlots',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          autoAcceptSubscriptions:
              $checkedConvert('autoAcceptSubscriptions', (v) => v as bool),
          acceptingToday: $checkedConvert('acceptingToday', (v) => v as bool),
          deliveryPaused: $checkedConvert('deliveryPaused', (v) => v as bool),
          allowKhataOrders:
              $checkedConvert('allowKhataOrders', (v) => v as bool),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorSettingsResponseToJson(
        VendorSettingsResponse instance) =>
    <String, dynamic>{
      'serviceRadiusKm': instance.serviceRadiusKm,
      'deliveryChargePaise': instance.deliveryChargePaise,
      'minOrderPaise': instance.minOrderPaise,
      'timeSlots': instance.timeSlots,
      'autoAcceptSubscriptions': instance.autoAcceptSubscriptions,
      'acceptingToday': instance.acceptingToday,
      'deliveryPaused': instance.deliveryPaused,
      'allowKhataOrders': instance.allowKhataOrders,
      'version': instance.version,
    };
