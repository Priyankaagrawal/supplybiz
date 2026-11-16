// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_subscription_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorSubscriptionInput _$VendorSubscriptionInputFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorSubscriptionInput',
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
            'paymentMethod'
          ],
        );
        final val = VendorSubscriptionInput(
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
                  _$VendorSubscriptionInputPaymentMethodEnumEnumMap, v)),
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String?),
          newCustomer: $checkedConvert(
              'newCustomer',
              (v) => v == null
                  ? null
                  : CustomerInput.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorSubscriptionInputToJson(
        VendorSubscriptionInput instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'qty': instance.qty,
      'weekdays': instance.weekdays,
      'startDate': instance.startDate.toIso8601String(),
      if (instance.endDate?.toIso8601String() case final value?)
        'endDate': value,
      'timeSlot': instance.timeSlot,
      'paymentMethod': _$VendorSubscriptionInputPaymentMethodEnumEnumMap[
          instance.paymentMethod]!,
      if (instance.vendorCustomerId case final value?)
        'vendorCustomerId': value,
      if (instance.newCustomer?.toJson() case final value?)
        'newCustomer': value,
    };

const _$VendorSubscriptionInputPaymentMethodEnumEnumMap = {
  VendorSubscriptionInputPaymentMethodEnum.CASH: 'CASH',
  VendorSubscriptionInputPaymentMethodEnum.UPI: 'UPI',
  VendorSubscriptionInputPaymentMethodEnum.WALLET: 'WALLET',
};
