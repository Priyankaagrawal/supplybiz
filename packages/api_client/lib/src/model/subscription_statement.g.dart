// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_statement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionStatement _$SubscriptionStatementFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionStatement',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'subscriptionId',
            'month',
            'items',
            'total',
            'deliveredAmountPaise',
            'deliveredQty',
            'ledger'
          ],
        );
        final val = SubscriptionStatement(
          subscriptionId: $checkedConvert('subscriptionId', (v) => v as String),
          month: $checkedConvert('month', (v) => v as String),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      SubscriptionDelivery.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          deliveredAmountPaise:
              $checkedConvert('deliveredAmountPaise', (v) => v as String),
          deliveredQty: $checkedConvert('deliveredQty', (v) => v as String),
          ledger: $checkedConvert('ledger',
              (v) => KhataVendorEntries.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionStatementToJson(
        SubscriptionStatement instance) =>
    <String, dynamic>{
      'subscriptionId': instance.subscriptionId,
      'month': instance.month,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'deliveredAmountPaise': instance.deliveredAmountPaise,
      'deliveredQty': instance.deliveredQty,
      'ledger': instance.ledger.toJson(),
    };
