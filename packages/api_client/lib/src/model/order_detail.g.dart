// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDetail _$OrderDetailFromJson(Map<String, dynamic> json) => $checkedCreate(
      'OrderDetail',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'orderNo',
            'vendorId',
            'status',
            'version',
            'deliveryDate',
            'timeSlot',
            'totalPaise',
            'paymentMode',
            'paymentStatus',
            'source',
            'createdAt',
            'vendorName',
            'customerName',
            'customerMobile',
            'address',
            'items',
            'timeline',
            'subtotalPaise',
            'deliveryChargePaise',
            'discountPaise',
            'rejectReason',
            'cancelReason',
            'failReason'
          ],
        );
        final val = OrderDetail(
          id: $checkedConvert('id', (v) => v as String),
          orderNo: $checkedConvert('orderNo', (v) => v as String),
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          deliveryDate: $checkedConvert(
              'deliveryDate', (v) => DateTime.parse(v as String)),
          timeSlot: $checkedConvert('timeSlot', (v) => v as String),
          totalPaise: $checkedConvert('totalPaise', (v) => v as String),
          paymentMode: $checkedConvert('paymentMode', (v) => v as String),
          paymentStatus: $checkedConvert('paymentStatus', (v) => v as String),
          source_: $checkedConvert('source', (v) => v as String),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
          vendorName: $checkedConvert('vendorName', (v) => v as String?),
          customerName: $checkedConvert('customerName', (v) => v as String),
          customerMobile: $checkedConvert('customerMobile', (v) => v as String),
          address: $checkedConvert('address',
              (v) => AddressResponse.fromJson(v as Map<String, dynamic>)),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      OrderPricedLine.fromJson(e as Map<String, dynamic>))
                  .toList()),
          timeline: $checkedConvert(
              'timeline',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      OrderStatusEvent.fromJson(e as Map<String, dynamic>))
                  .toList()),
          subtotalPaise: $checkedConvert('subtotalPaise', (v) => v as String),
          deliveryChargePaise:
              $checkedConvert('deliveryChargePaise', (v) => v as String),
          discountPaise: $checkedConvert('discountPaise', (v) => v as String),
          rejectReason: $checkedConvert('rejectReason', (v) => v as String?),
          cancelReason: $checkedConvert('cancelReason', (v) => v as String?),
          failReason: $checkedConvert('failReason', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'source_': 'source'},
    );

Map<String, dynamic> _$OrderDetailToJson(OrderDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderNo': instance.orderNo,
      'vendorId': instance.vendorId,
      'status': instance.status,
      'version': instance.version,
      'deliveryDate': instance.deliveryDate.toIso8601String(),
      'timeSlot': instance.timeSlot,
      'totalPaise': instance.totalPaise,
      'paymentMode': instance.paymentMode,
      'paymentStatus': instance.paymentStatus,
      'source': instance.source_,
      'createdAt': instance.createdAt,
      'vendorName': instance.vendorName,
      'customerName': instance.customerName,
      'customerMobile': instance.customerMobile,
      'address': instance.address.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'timeline': instance.timeline.map((e) => e.toJson()).toList(),
      'subtotalPaise': instance.subtotalPaise,
      'deliveryChargePaise': instance.deliveryChargePaise,
      'discountPaise': instance.discountPaise,
      'rejectReason': instance.rejectReason,
      'cancelReason': instance.cancelReason,
      'failReason': instance.failReason,
    };
