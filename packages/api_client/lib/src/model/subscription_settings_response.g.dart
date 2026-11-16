// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_settings_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionSettingsResponse _$SubscriptionSettingsResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionSettingsResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'version',
            'serverTime',
            'businessDate',
            'autoAcceptSubscriptions',
            'effectiveAutoAcceptSubscriptions',
            'canAutoAccept',
            'canEditSubscriptions',
            'canReduceActivity',
            'deliveryAvailable',
            'deliveryStartTime',
            'deliveryEndTime',
            'maxDailyOrders',
            'dailyMilkCapacityLitres',
            'pauseAllSubscriptions',
            'summary'
          ],
        );
        final val = SubscriptionSettingsResponse(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          autoAcceptSubscriptions:
              $checkedConvert('autoAcceptSubscriptions', (v) => v as bool),
          effectiveAutoAcceptSubscriptions: $checkedConvert(
              'effectiveAutoAcceptSubscriptions', (v) => v as bool),
          canAutoAccept: $checkedConvert('canAutoAccept', (v) => v as bool),
          canEditSubscriptions:
              $checkedConvert('canEditSubscriptions', (v) => v as bool),
          canReduceActivity:
              $checkedConvert('canReduceActivity', (v) => v as bool),
          deliveryAvailable:
              $checkedConvert('deliveryAvailable', (v) => v as bool),
          deliveryStartTime:
              $checkedConvert('deliveryStartTime', (v) => v as String?),
          deliveryEndTime:
              $checkedConvert('deliveryEndTime', (v) => v as String?),
          maxDailyOrders:
              $checkedConvert('maxDailyOrders', (v) => (v as num?)?.toInt()),
          dailyMilkCapacityLitres:
              $checkedConvert('dailyMilkCapacityLitres', (v) => v as String?),
          pauseAllSubscriptions:
              $checkedConvert('pauseAllSubscriptions', (v) => v as bool),
          summary: $checkedConvert(
              'summary',
              (v) => SubscriptionSettingsSummary.fromJson(
                  v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionSettingsResponseToJson(
        SubscriptionSettingsResponse instance) =>
    <String, dynamic>{
      'version': instance.version,
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
      'autoAcceptSubscriptions': instance.autoAcceptSubscriptions,
      'effectiveAutoAcceptSubscriptions':
          instance.effectiveAutoAcceptSubscriptions,
      'canAutoAccept': instance.canAutoAccept,
      'canEditSubscriptions': instance.canEditSubscriptions,
      'canReduceActivity': instance.canReduceActivity,
      'deliveryAvailable': instance.deliveryAvailable,
      'deliveryStartTime': instance.deliveryStartTime,
      'deliveryEndTime': instance.deliveryEndTime,
      'maxDailyOrders': instance.maxDailyOrders,
      'dailyMilkCapacityLitres': instance.dailyMilkCapacityLitres,
      'pauseAllSubscriptions': instance.pauseAllSubscriptions,
      'summary': instance.summary.toJson(),
    };
