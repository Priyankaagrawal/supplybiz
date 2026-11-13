// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_transition_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderTransitionInput _$OrderTransitionInputFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderTransitionInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['to', 'version'],
        );
        final val = OrderTransitionInput(
          to: $checkedConvert(
              'to', (v) => $enumDecode(_$OrderTransitionInputToEnumEnumMap, v)),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          reason: $checkedConvert('reason', (v) => v as String?),
          reasonText: $checkedConvert('reasonText', (v) => v as String?),
          payment: $checkedConvert(
              'payment',
              (v) => v == null
                  ? null
                  : DeliveryPaymentInput.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderTransitionInputToJson(
        OrderTransitionInput instance) =>
    <String, dynamic>{
      'to': _$OrderTransitionInputToEnumEnumMap[instance.to]!,
      'version': instance.version,
      if (instance.reason case final value?) 'reason': value,
      if (instance.reasonText case final value?) 'reasonText': value,
      if (instance.payment?.toJson() case final value?) 'payment': value,
    };

const _$OrderTransitionInputToEnumEnumMap = {
  OrderTransitionInputToEnum.ACCEPTED: 'ACCEPTED',
  OrderTransitionInputToEnum.REJECTED: 'REJECTED',
  OrderTransitionInputToEnum.PREPARING: 'PREPARING',
  OrderTransitionInputToEnum.OUT_FOR_DELIVERY: 'OUT_FOR_DELIVERY',
  OrderTransitionInputToEnum.DELIVERED: 'DELIVERED',
  OrderTransitionInputToEnum.FAILED: 'FAILED',
};
