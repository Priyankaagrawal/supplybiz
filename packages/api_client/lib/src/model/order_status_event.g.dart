// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_status_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderStatusEvent _$OrderStatusEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderStatusEvent',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['status', 'reason', 'at'],
        );
        final val = OrderStatusEvent(
          status: $checkedConvert('status', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String?),
          at: $checkedConvert('at', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderStatusEventToJson(OrderStatusEvent instance) =>
    <String, dynamic>{
      'status': instance.status,
      'reason': instance.reason,
      'at': instance.at,
    };
