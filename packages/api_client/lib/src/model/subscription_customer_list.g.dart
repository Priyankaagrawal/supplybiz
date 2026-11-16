// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_customer_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionCustomerList _$SubscriptionCustomerListFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionCustomerList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total', 'serverTime', 'businessDate'],
        );
        final val = SubscriptionCustomerList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      SubscriptionCustomer.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionCustomerListToJson(
        SubscriptionCustomerList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
    };
