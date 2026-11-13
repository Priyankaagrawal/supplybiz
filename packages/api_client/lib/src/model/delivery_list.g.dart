// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryList _$DeliveryListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeliveryList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'serverTime',
            'businessDate',
            'deliveryDate',
            'counts',
            'items',
            'total'
          ],
        );
        final val = DeliveryList(
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert('businessDate', (v) => v as String),
          deliveryDate: $checkedConvert('deliveryDate', (v) => v as String),
          counts: $checkedConvert('counts',
              (v) => DeliveryCounts.fromJson(v as Map<String, dynamic>)),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => OrderDetail.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$DeliveryListToJson(DeliveryList instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate,
      'deliveryDate': instance.deliveryDate,
      'counts': instance.counts.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
