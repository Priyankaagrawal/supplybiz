// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_about.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorAbout _$VendorAboutFromJson(Map<String, dynamic> json) => $checkedCreate(
      'VendorAbout',
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
            'favorite',
            'address',
            'city',
            'state',
            'pincode',
            'deliveryChargePaise',
            'minOrderPaise',
            'openingHours',
            'holidays'
          ],
        );
        final val = VendorAbout(
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
          address: $checkedConvert('address', (v) => v as String?),
          city: $checkedConvert('city', (v) => v as String?),
          state: $checkedConvert('state', (v) => v as String?),
          pincode: $checkedConvert('pincode', (v) => v as String?),
          deliveryChargePaise:
              $checkedConvert('deliveryChargePaise', (v) => (v as num).toInt()),
          minOrderPaise:
              $checkedConvert('minOrderPaise', (v) => (v as num).toInt()),
          openingHours: $checkedConvert(
              'openingHours',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as Object),
                  )),
          holidays: $checkedConvert(
              'holidays',
              (v) => (v as List<dynamic>)
                  .map((e) => VendorAboutHolidaysInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorAboutToJson(VendorAbout instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessName': instance.businessName,
      'categoryId': instance.categoryId,
      'shopPhotoMediaId': instance.shopPhotoMediaId,
      'badges': instance.badges,
      'distanceMeters': instance.distanceMeters,
      'completedOrders30Days': instance.completedOrders30Days,
      'favorite': instance.favorite,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'pincode': instance.pincode,
      'deliveryChargePaise': instance.deliveryChargePaise,
      'minOrderPaise': instance.minOrderPaise,
      'openingHours': instance.openingHours,
      'holidays': instance.holidays.map((e) => e.toJson()).toList(),
    };
