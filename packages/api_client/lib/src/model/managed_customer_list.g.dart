// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_customer_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedCustomerList _$ManagedCustomerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ManagedCustomerList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = ManagedCustomerList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ManagedCustomer.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ManagedCustomerListToJson(
        ManagedCustomerList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
