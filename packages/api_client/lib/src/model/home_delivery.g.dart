// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_delivery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeDelivery _$HomeDeliveryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HomeDelivery',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'orderNo',
            'vendorId',
            'vendorName',
            'source',
            'status',
            'deliveryDate',
            'timeSlot',
            'items'
          ],
        );
        final val = HomeDelivery(
          id: $checkedConvert('id', (v) => v as String),
          orderNo: $checkedConvert('orderNo', (v) => v as String),
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          vendorName: $checkedConvert('vendorName', (v) => v as String?),
          source_: $checkedConvert('source',
              (v) => $enumDecode(_$HomeDeliverySource_EnumEnumMap, v)),
          status: $checkedConvert(
              'status', (v) => $enumDecode(_$HomeDeliveryStatusEnumEnumMap, v)),
          deliveryDate: $checkedConvert(
              'deliveryDate', (v) => DateTime.parse(v as String)),
          timeSlot: $checkedConvert('timeSlot', (v) => v as String),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      HomeDeliveryItem.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {'source_': 'source'},
    );

Map<String, dynamic> _$HomeDeliveryToJson(HomeDelivery instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderNo': instance.orderNo,
      'vendorId': instance.vendorId,
      'vendorName': instance.vendorName,
      'source': _$HomeDeliverySource_EnumEnumMap[instance.source_]!,
      'status': _$HomeDeliveryStatusEnumEnumMap[instance.status]!,
      'deliveryDate': instance.deliveryDate.toIso8601String(),
      'timeSlot': instance.timeSlot,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$HomeDeliverySource_EnumEnumMap = {
  HomeDeliverySource_Enum.APP: 'APP',
  HomeDeliverySource_Enum.SUBSCRIPTION: 'SUBSCRIPTION',
  HomeDeliverySource_Enum.VENDOR: 'VENDOR',
};

const _$HomeDeliveryStatusEnumEnumMap = {
  HomeDeliveryStatusEnum.NEW: 'NEW',
  HomeDeliveryStatusEnum.ACCEPTED: 'ACCEPTED',
  HomeDeliveryStatusEnum.REJECTED: 'REJECTED',
  HomeDeliveryStatusEnum.PREPARING: 'PREPARING',
  HomeDeliveryStatusEnum.OUT_FOR_DELIVERY: 'OUT_FOR_DELIVERY',
  HomeDeliveryStatusEnum.DELIVERED: 'DELIVERED',
  HomeDeliveryStatusEnum.FAILED: 'FAILED',
  HomeDeliveryStatusEnum.CANCELLED: 'CANCELLED',
};
