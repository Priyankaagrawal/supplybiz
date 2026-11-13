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
          reason: $checkedConvert(
              'reason',
              (v) => $enumDecodeNullable(
                  _$OrderTransitionInputReasonEnumEnumMap, v)),
          reasonText: $checkedConvert('reasonText', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderTransitionInputToJson(
        OrderTransitionInput instance) =>
    <String, dynamic>{
      'to': _$OrderTransitionInputToEnumEnumMap[instance.to]!,
      'version': instance.version,
      if (_$OrderTransitionInputReasonEnumEnumMap[instance.reason]
          case final value?)
        'reason': value,
      if (instance.reasonText case final value?) 'reasonText': value,
    };

const _$OrderTransitionInputToEnumEnumMap = {
  OrderTransitionInputToEnum.ACCEPTED: 'ACCEPTED',
  OrderTransitionInputToEnum.REJECTED: 'REJECTED',
  OrderTransitionInputToEnum.PREPARING: 'PREPARING',
  OrderTransitionInputToEnum.OUT_FOR_DELIVERY: 'OUT_FOR_DELIVERY',
};

const _$OrderTransitionInputReasonEnumEnumMap = {
  OrderTransitionInputReasonEnum.CUSTOMER_UNAVAILABLE: 'CUSTOMER_UNAVAILABLE',
  OrderTransitionInputReasonEnum.OUT_OF_STOCK: 'OUT_OF_STOCK',
  OrderTransitionInputReasonEnum.NOT_SERVICEABLE: 'NOT_SERVICEABLE',
  OrderTransitionInputReasonEnum.CUSTOMER_REQUEST: 'CUSTOMER_REQUEST',
  OrderTransitionInputReasonEnum.OTHER: 'OTHER',
};
