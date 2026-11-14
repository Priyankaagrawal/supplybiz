// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_unavailable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReorderUnavailable _$ReorderUnavailableFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReorderUnavailable',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['productId', 'name', 'reason'],
        );
        final val = ReorderUnavailable(
          productId: $checkedConvert('productId', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          reason: $checkedConvert('reason',
              (v) => $enumDecode(_$ReorderUnavailableReasonEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReorderUnavailableToJson(ReorderUnavailable instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'name': instance.name,
      'reason': _$ReorderUnavailableReasonEnumEnumMap[instance.reason]!,
    };

const _$ReorderUnavailableReasonEnumEnumMap = {
  ReorderUnavailableReasonEnum.PRODUCT_UNAVAILABLE: 'PRODUCT_UNAVAILABLE',
  ReorderUnavailableReasonEnum.BELOW_MOQ: 'BELOW_MOQ',
  ReorderUnavailableReasonEnum.INSUFFICIENT_STOCK: 'INSUFFICIENT_STOCK',
};
