// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovered_vendor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoveredVendor _$DiscoveredVendorFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DiscoveredVendor',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'businessName',
            'categoryId',
            'shopPhotoMediaId',
            'badges',
            'distanceMeters',
            'completedOrders30Days',
            'favorite'
          ],
        );
        final val = DiscoveredVendor(
          id: $checkedConvert('id', (v) => v as String),
          businessName: $checkedConvert('businessName', (v) => v as String),
          categoryId: $checkedConvert('categoryId', (v) => v as String),
          shopPhotoMediaId:
              $checkedConvert('shopPhotoMediaId', (v) => v as String?),
          badges: $checkedConvert('badges',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          distanceMeters: $checkedConvert('distanceMeters', (v) => v as num),
          completedOrders30Days: $checkedConvert(
              'completedOrders30Days', (v) => (v as num).toInt()),
          favorite: $checkedConvert('favorite', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$DiscoveredVendorToJson(DiscoveredVendor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessName': instance.businessName,
      'categoryId': instance.categoryId,
      'shopPhotoMediaId': instance.shopPhotoMediaId,
      'badges': instance.badges,
      'distanceMeters': instance.distanceMeters,
      'completedOrders30Days': instance.completedOrders30Days,
      'favorite': instance.favorite,
    };
