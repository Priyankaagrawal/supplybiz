// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_reorder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderReorder _$OrderReorderFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderReorder',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'vendorId',
            'vendorName',
            'items',
            'unavailable'
          ],
        );
        final val = OrderReorder(
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          vendorName: $checkedConvert('vendorName', (v) => v as String),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => ReorderLine.fromJson(e as Map<String, dynamic>))
                  .toList()),
          unavailable: $checkedConvert(
              'unavailable',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ReorderUnavailable.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderReorderToJson(OrderReorder instance) =>
    <String, dynamic>{
      'vendorId': instance.vendorId,
      'vendorName': instance.vendorName,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'unavailable': instance.unavailable.map((e) => e.toJson()).toList(),
    };
