// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionList _$SubscriptionListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['serverTime', 'businessDate', 'items', 'total'],
        );
        final val = SubscriptionList(
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      SubscriptionRecord.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionListToJson(SubscriptionList instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
