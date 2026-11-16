// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionPlan',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'productId',
            'productName',
            'kind',
            'qty',
            'dailyAmountPaise',
            'monthlyEstimatePaise',
            'mostPopular'
          ],
        );
        final val = SubscriptionPlan(
          productId: $checkedConvert('productId', (v) => v as String),
          productName: $checkedConvert('productName', (v) => v as String),
          kind: $checkedConvert('kind', (v) => v as String),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
          dailyAmountPaise:
              $checkedConvert('dailyAmountPaise', (v) => v as String),
          monthlyEstimatePaise:
              $checkedConvert('monthlyEstimatePaise', (v) => v as String),
          mostPopular: $checkedConvert('mostPopular', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionPlanToJson(SubscriptionPlan instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'kind': instance.kind,
      'qty': instance.qty,
      'dailyAmountPaise': instance.dailyAmountPaise,
      'monthlyEstimatePaise': instance.monthlyEstimatePaise,
      'mostPopular': instance.mostPopular,
    };
