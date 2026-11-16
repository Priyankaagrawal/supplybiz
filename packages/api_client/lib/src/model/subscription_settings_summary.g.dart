// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_settings_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionSettingsSummary _$SubscriptionSettingsSummaryFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionSettingsSummary',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'totalSubscriptions',
            'active',
            'paused',
            'pendingApproval',
            'cancelled',
            'rejected',
            'completed',
            'subscriptionCustomers'
          ],
        );
        final val = SubscriptionSettingsSummary(
          totalSubscriptions:
              $checkedConvert('totalSubscriptions', (v) => (v as num).toInt()),
          active: $checkedConvert('active', (v) => (v as num).toInt()),
          paused: $checkedConvert('paused', (v) => (v as num).toInt()),
          pendingApproval:
              $checkedConvert('pendingApproval', (v) => (v as num).toInt()),
          cancelled: $checkedConvert('cancelled', (v) => (v as num).toInt()),
          rejected: $checkedConvert('rejected', (v) => (v as num).toInt()),
          completed: $checkedConvert('completed', (v) => (v as num).toInt()),
          subscriptionCustomers: $checkedConvert(
              'subscriptionCustomers', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionSettingsSummaryToJson(
        SubscriptionSettingsSummary instance) =>
    <String, dynamic>{
      'totalSubscriptions': instance.totalSubscriptions,
      'active': instance.active,
      'paused': instance.paused,
      'pendingApproval': instance.pendingApproval,
      'cancelled': instance.cancelled,
      'rejected': instance.rejected,
      'completed': instance.completed,
      'subscriptionCustomers': instance.subscriptionCustomers,
    };
