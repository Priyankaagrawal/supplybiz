// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_counts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryCounts _$DeliveryCountsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeliveryCounts',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'ALL',
            'PENDING',
            'PREPARING',
            'OUT_FOR_DELIVERY',
            'DELIVERED',
            'FAILED'
          ],
        );
        final val = DeliveryCounts(
          ALL: $checkedConvert('ALL', (v) => (v as num).toInt()),
          PENDING: $checkedConvert('PENDING', (v) => (v as num).toInt()),
          PREPARING: $checkedConvert('PREPARING', (v) => (v as num).toInt()),
          OUT_FOR_DELIVERY:
              $checkedConvert('OUT_FOR_DELIVERY', (v) => (v as num).toInt()),
          DELIVERED: $checkedConvert('DELIVERED', (v) => (v as num).toInt()),
          FAILED: $checkedConvert('FAILED', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$DeliveryCountsToJson(DeliveryCounts instance) =>
    <String, dynamic>{
      'ALL': instance.ALL,
      'PENDING': instance.PENDING,
      'PREPARING': instance.PREPARING,
      'OUT_FOR_DELIVERY': instance.OUT_FOR_DELIVERY,
      'DELIVERED': instance.DELIVERED,
      'FAILED': instance.FAILED,
    };
