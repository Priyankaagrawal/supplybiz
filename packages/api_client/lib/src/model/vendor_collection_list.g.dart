// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_collection_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorCollectionList _$VendorCollectionListFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorCollectionList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total', 'month'],
        );
        final val = VendorCollectionList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      VendorCollection.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          month: $checkedConvert('month', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorCollectionListToJson(
        VendorCollectionList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'month': instance.month,
    };
