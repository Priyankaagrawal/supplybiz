// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPreferences _$NotificationPreferencesFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'NotificationPreferences',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['orders', 'payments', 'delivery', 'system'],
        );
        final val = NotificationPreferences(
          orders: $checkedConvert('orders', (v) => v as bool),
          payments: $checkedConvert('payments', (v) => v as bool),
          delivery: $checkedConvert('delivery', (v) => v as bool),
          system: $checkedConvert('system', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$NotificationPreferencesToJson(
        NotificationPreferences instance) =>
    <String, dynamic>{
      'orders': instance.orders,
      'payments': instance.payments,
      'delivery': instance.delivery,
      'system': instance.system,
    };
