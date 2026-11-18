// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_delivery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionDelivery _$SubscriptionDeliveryFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionDelivery',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'orderId',
            'deliveryDate',
            'productName',
            'qty',
            'amountPaise',
            'paymentStatus'
          ],
        );
        final val = SubscriptionDelivery(
          orderId: $checkedConvert('orderId', (v) => v as String),
          deliveryDate: $checkedConvert(
              'deliveryDate', (v) => DateTime.parse(v as String)),
          productName: $checkedConvert('productName', (v) => v as String),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          paymentStatus: $checkedConvert('paymentStatus', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionDeliveryToJson(
        SubscriptionDelivery instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'deliveryDate': instance.deliveryDate.toIso8601String(),
      'productName': instance.productName,
      'qty': instance.qty,
      'amountPaise': instance.amountPaise,
      'paymentStatus': instance.paymentStatus,
    };
