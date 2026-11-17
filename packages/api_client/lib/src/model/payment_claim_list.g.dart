// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_claim_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentClaimList _$PaymentClaimListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentClaimList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = PaymentClaimList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      PaymentClaimRecord.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentClaimListToJson(PaymentClaimList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
