// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderResult _$OrderResultFromJson(Map<String, dynamic> json) => $checkedCreate(
      'OrderResult',
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
            'createdAt'
          ],
        );
        final val = OrderResult(
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
        );
        return val;
      },
      fieldKeyMap: const {'source_': 'source'},
    );

Map<String, dynamic> _$OrderResultToJson(OrderResult instance) =>
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
    };
