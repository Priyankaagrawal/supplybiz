// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentList _$PaymentListFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PaymentList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = PaymentList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentListToJson(PaymentList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
