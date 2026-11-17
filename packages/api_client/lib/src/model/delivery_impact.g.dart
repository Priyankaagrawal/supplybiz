// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_impact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryImpact _$DeliveryImpactFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeliveryImpact',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['affectedOrders', 'serverTime', 'businessDate'],
        );
        final val = DeliveryImpact(
          affectedOrders:
              $checkedConvert('affectedOrders', (v) => (v as num).toInt()),
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$DeliveryImpactToJson(DeliveryImpact instance) =>
    <String, dynamic>{
      'affectedOrders': instance.affectedOrders,
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
    };
