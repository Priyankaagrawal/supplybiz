// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_line_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleLineInput _$SaleLineInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SaleLineInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['productId', 'qty'],
        );
        final val = SaleLineInput(
          productId: $checkedConvert('productId', (v) => v as String),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
          ratePaise: $checkedConvert('ratePaise', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SaleLineInputToJson(SaleLineInput instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'qty': instance.qty,
      if (instance.ratePaise case final value?) 'ratePaise': value,
    };
