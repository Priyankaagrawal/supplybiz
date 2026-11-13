// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_place_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderPlaceInput _$OrderPlaceInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderPlaceInput',
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
            'items',
            'expectedTotalPaise'
          ],
        );
        final val = OrderPlaceInput(
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          addressId: $checkedConvert('addressId', (v) => v as String),
          deliveryDate: $checkedConvert(
              'deliveryDate', (v) => DateTime.parse(v as String)),
          timeSlot: $checkedConvert('timeSlot', (v) => v as String),
          paymentMode: $checkedConvert('paymentMode',
              (v) => $enumDecode(_$OrderPlaceInputPaymentModeEnumEnumMap, v)),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => OrderLineInput.fromJson(e as Map<String, dynamic>))
                  .toList()),
          expectedTotalPaise:
              $checkedConvert('expectedTotalPaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderPlaceInputToJson(OrderPlaceInput instance) =>
    <String, dynamic>{
      'vendorId': instance.vendorId,
      'addressId': instance.addressId,
      'deliveryDate': instance.deliveryDate.toIso8601String(),
      'timeSlot': instance.timeSlot,
      'paymentMode':
          _$OrderPlaceInputPaymentModeEnumEnumMap[instance.paymentMode]!,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'expectedTotalPaise': instance.expectedTotalPaise,
    };

const _$OrderPlaceInputPaymentModeEnumEnumMap = {
  OrderPlaceInputPaymentModeEnum.POD_CASH: 'POD_CASH',
  OrderPlaceInputPaymentModeEnum.POD_UPI: 'POD_UPI',
};
