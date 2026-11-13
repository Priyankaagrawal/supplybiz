// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_quote_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderQuoteInput _$OrderQuoteInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderQuoteInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'vendorId',
            'addressId',
            'deliveryDate',
            'timeSlot',
            'paymentMode',
            'items'
          ],
        );
        final val = OrderQuoteInput(
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          addressId: $checkedConvert('addressId', (v) => v as String),
          deliveryDate: $checkedConvert(
              'deliveryDate', (v) => DateTime.parse(v as String)),
          timeSlot: $checkedConvert('timeSlot', (v) => v as String),
          paymentMode: $checkedConvert('paymentMode',
              (v) => $enumDecode(_$OrderQuoteInputPaymentModeEnumEnumMap, v)),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => OrderLineInput.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderQuoteInputToJson(OrderQuoteInput instance) =>
    <String, dynamic>{
      'vendorId': instance.vendorId,
      'addressId': instance.addressId,
      'deliveryDate': instance.deliveryDate.toIso8601String(),
      'timeSlot': instance.timeSlot,
      'paymentMode':
          _$OrderQuoteInputPaymentModeEnumEnumMap[instance.paymentMode]!,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$OrderQuoteInputPaymentModeEnumEnumMap = {
  OrderQuoteInputPaymentModeEnum.POD_CASH: 'POD_CASH',
  OrderQuoteInputPaymentModeEnum.POD_UPI: 'POD_UPI',
};
