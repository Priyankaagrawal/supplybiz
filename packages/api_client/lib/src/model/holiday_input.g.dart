// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HolidayInput _$HolidayInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HolidayInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['date', 'reason'],
        );
        final val = HolidayInput(
          date: $checkedConvert('date', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$HolidayInputToJson(HolidayInput instance) =>
    <String, dynamic>{
      'date': instance.date,
      'reason': instance.reason,
    };
