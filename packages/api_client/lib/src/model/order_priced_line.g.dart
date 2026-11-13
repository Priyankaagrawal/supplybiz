// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_priced_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderPricedLine _$OrderPricedLineFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderPricedLine',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'productId',
            'name',
            'unitValue',
            'unitType',
            'qty',
            'unitPricePaise',
            'lineTotalPaise'
          ],
        );
        final val = OrderPricedLine(
          productId: $checkedConvert('productId', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          unitValue: $checkedConvert('unitValue', (v) => v as String),
          unitType: $checkedConvert('unitType', (v) => v as String),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
          unitPricePaise: $checkedConvert('unitPricePaise', (v) => v as String),
          lineTotalPaise: $checkedConvert('lineTotalPaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderPricedLineToJson(OrderPricedLine instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'name': instance.name,
      'unitValue': instance.unitValue,
      'unitType': instance.unitType,
      'qty': instance.qty,
      'unitPricePaise': instance.unitPricePaise,
      'lineTotalPaise': instance.lineTotalPaise,
    };
