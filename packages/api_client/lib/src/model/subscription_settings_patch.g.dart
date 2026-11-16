// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_settings_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionSettingsPatch _$SubscriptionSettingsPatchFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionSettingsPatch',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = SubscriptionSettingsPatch(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          autoAcceptSubscriptions:
              $checkedConvert('autoAcceptSubscriptions', (v) => v as bool?),
          deliveryAvailable:
              $checkedConvert('deliveryAvailable', (v) => v as bool?),
          deliveryStartTime:
              $checkedConvert('deliveryStartTime', (v) => v as String?),
          deliveryEndTime:
              $checkedConvert('deliveryEndTime', (v) => v as String?),
          maxDailyOrders:
              $checkedConvert('maxDailyOrders', (v) => (v as num?)?.toInt()),
          dailyMilkCapacityLitres:
              $checkedConvert('dailyMilkCapacityLitres', (v) => v as String?),
          pauseAllSubscriptions:
              $checkedConvert('pauseAllSubscriptions', (v) => v as bool?),
          clearDeliveryWindow:
              $checkedConvert('clearDeliveryWindow', (v) => v as bool?),
          clearMaxDailyOrders:
              $checkedConvert('clearMaxDailyOrders', (v) => v as bool?),
          clearDailyMilkCapacity:
              $checkedConvert('clearDailyMilkCapacity', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionSettingsPatchToJson(
        SubscriptionSettingsPatch instance) =>
    <String, dynamic>{
      'version': instance.version,
      if (instance.autoAcceptSubscriptions case final value?)
        'autoAcceptSubscriptions': value,
      if (instance.deliveryAvailable case final value?)
        'deliveryAvailable': value,
      if (instance.deliveryStartTime case final value?)
        'deliveryStartTime': value,
      if (instance.deliveryEndTime case final value?) 'deliveryEndTime': value,
      if (instance.maxDailyOrders case final value?) 'maxDailyOrders': value,
      if (instance.dailyMilkCapacityLitres case final value?)
        'dailyMilkCapacityLitres': value,
      if (instance.pauseAllSubscriptions case final value?)
        'pauseAllSubscriptions': value,
      if (instance.clearDeliveryWindow case final value?)
        'clearDeliveryWindow': value,
      if (instance.clearMaxDailyOrders case final value?)
        'clearMaxDailyOrders': value,
      if (instance.clearDailyMilkCapacity case final value?)
        'clearDailyMilkCapacity': value,
    };
