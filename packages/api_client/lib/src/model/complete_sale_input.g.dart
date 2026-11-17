// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_sale_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompleteSaleInput _$CompleteSaleInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CompleteSaleInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'paidPaise', 'paymentMethod'],
        );
        final val = CompleteSaleInput(
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String?),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => SaleLineInput.fromJson(e as Map<String, dynamic>))
                  .toList()),
          paidPaise: $checkedConvert('paidPaise', (v) => v as String),
          paymentMethod: $checkedConvert(
              'paymentMethod',
              (v) =>
                  $enumDecode(_$CompleteSaleInputPaymentMethodEnumEnumMap, v)),
          clientCreatedAt: $checkedConvert('clientCreatedAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$CompleteSaleInputToJson(CompleteSaleInput instance) =>
    <String, dynamic>{
      if (instance.vendorCustomerId case final value?)
        'vendorCustomerId': value,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'paidPaise': instance.paidPaise,
      'paymentMethod':
          _$CompleteSaleInputPaymentMethodEnumEnumMap[instance.paymentMethod]!,
      if (instance.clientCreatedAt?.toIso8601String() case final value?)
        'clientCreatedAt': value,
    };

const _$CompleteSaleInputPaymentMethodEnumEnumMap = {
  CompleteSaleInputPaymentMethodEnum.CASH: 'CASH',
  CompleteSaleInputPaymentMethodEnum.UPI: 'UPI',
  CompleteSaleInputPaymentMethodEnum.OTHER: 'OTHER',
};
