// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_subscription_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerSubscriptionInput _$CustomerSubscriptionInputFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'CustomerSubscriptionInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'productId',
            'qty',
            'weekdays',
            'startDate',
            'timeSlot',
            'paymentMethod',
            'vendorId',
            'addressId'
          ],
        );
        final val = CustomerSubscriptionInput(
          productId: $checkedConvert('productId', (v) => v as String),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
          weekdays: $checkedConvert('weekdays',
              (v) => (v as List<dynamic>).map((e) => e as num).toList()),
          startDate:
              $checkedConvert('startDate', (v) => DateTime.parse(v as String)),
          endDate: $checkedConvert(
              'endDate', (v) => v == null ? null : DateTime.parse(v as String)),
          timeSlot: $checkedConvert('timeSlot', (v) => v as String),
          paymentMethod: $checkedConvert(
              'paymentMethod',
              (v) => $enumDecode(
                  _$CustomerSubscriptionInputPaymentMethodEnumEnumMap, v)),
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          addressId: $checkedConvert('addressId', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$CustomerSubscriptionInputToJson(
        CustomerSubscriptionInput instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'qty': instance.qty,
      'weekdays': instance.weekdays,
      'startDate': instance.startDate.toIso8601String(),
      if (instance.endDate?.toIso8601String() case final value?)
        'endDate': value,
      'timeSlot': instance.timeSlot,
      'paymentMethod': _$CustomerSubscriptionInputPaymentMethodEnumEnumMap[
          instance.paymentMethod]!,
      'vendorId': instance.vendorId,
      'addressId': instance.addressId,
    };

const _$CustomerSubscriptionInputPaymentMethodEnumEnumMap = {
  CustomerSubscriptionInputPaymentMethodEnum.CASH: 'CASH',
  CustomerSubscriptionInputPaymentMethodEnum.UPI: 'UPI',
  CustomerSubscriptionInputPaymentMethodEnum.WALLET: 'WALLET',
};
