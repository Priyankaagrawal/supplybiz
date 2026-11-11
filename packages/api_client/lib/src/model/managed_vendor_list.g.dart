// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_vendor_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedVendorList _$ManagedVendorListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ManagedVendorList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = ManagedVendorList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => ManagedVendor.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ManagedVendorListToJson(ManagedVendorList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
