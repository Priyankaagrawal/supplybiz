// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_cancel_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderCancelInput _$OrderCancelInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderCancelInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = OrderCancelInput(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderCancelInputToJson(OrderCancelInput instance) =>
    <String, dynamic>{
      'version': instance.version,
    };
