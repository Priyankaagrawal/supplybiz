// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_mutation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HolidayMutation _$HolidayMutationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HolidayMutation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['holiday', 'cancelledOrders'],
        );
        final val = HolidayMutation(
          holiday: $checkedConvert('holiday',
              (v) => HolidayRecord.fromJson(v as Map<String, dynamic>)),
          cancelledOrders:
              $checkedConvert('cancelledOrders', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$HolidayMutationToJson(HolidayMutation instance) =>
    <String, dynamic>{
      'holiday': instance.holiday.toJson(),
      'cancelledOrders': instance.cancelledOrders,
    };
