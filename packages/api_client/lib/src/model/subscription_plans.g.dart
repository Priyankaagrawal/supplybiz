// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plans.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPlans _$SubscriptionPlansFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionPlans',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'items',
            'timeSlots',
            'freeDelivery',
            'earliestStartDate',
            'estimateMonth'
          ],
        );
        final val = SubscriptionPlans(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      SubscriptionPlan.fromJson(e as Map<String, dynamic>))
                  .toList()),
          timeSlots: $checkedConvert('timeSlots',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          freeDelivery: $checkedConvert('freeDelivery', (v) => v as bool),
          earliestStartDate: $checkedConvert(
              'earliestStartDate', (v) => DateTime.parse(v as String)),
          estimateMonth: $checkedConvert('estimateMonth', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionPlansToJson(SubscriptionPlans instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'timeSlots': instance.timeSlots,
      'freeDelivery': instance.freeDelivery,
      'earliestStartDate': instance.earliestStartDate.toIso8601String(),
      'estimateMonth': instance.estimateMonth,
    };
