// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_line_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderLineInput _$OrderLineInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderLineInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['productId', 'qty'],
        );
        final val = OrderLineInput(
          productId: $checkedConvert('productId', (v) => v as String),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderLineInputToJson(OrderLineInput instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'qty': instance.qty,
    };
