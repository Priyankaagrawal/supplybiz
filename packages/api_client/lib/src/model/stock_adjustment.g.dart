// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_adjustment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockAdjustment _$StockAdjustmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'StockAdjustment',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['delta', 'reason'],
        );
        final val = StockAdjustment(
          delta: $checkedConvert('delta', (v) => (v as num).toInt()),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$StockAdjustmentToJson(StockAdjustment instance) =>
    <String, dynamic>{
      'delta': instance.delta,
      'reason': instance.reason,
    };
