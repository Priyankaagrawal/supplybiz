// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_delivery_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeDeliveryItem _$HomeDeliveryItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HomeDeliveryItem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['productId', 'name', 'qty'],
        );
        final val = HomeDeliveryItem(
          productId: $checkedConvert('productId', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$HomeDeliveryItemToJson(HomeDeliveryItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'name': instance.name,
      'qty': instance.qty,
    };
