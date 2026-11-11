// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerList _$CustomerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CustomerList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'items',
            'total',
            'activeCount',
            'customerLimit'
          ],
        );
        final val = CustomerList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      CustomerResponse.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          activeCount:
              $checkedConvert('activeCount', (v) => (v as num).toInt()),
          customerLimit:
              $checkedConvert('customerLimit', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$CustomerListToJson(CustomerList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'activeCount': instance.activeCount,
      'customerLimit': instance.customerLimit,
    };
