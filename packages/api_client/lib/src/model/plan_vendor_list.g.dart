// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_vendor_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanVendorList _$PlanVendorListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanVendorList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = PlanVendorList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => PlanVendorRow.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanVendorListToJson(PlanVendorList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
