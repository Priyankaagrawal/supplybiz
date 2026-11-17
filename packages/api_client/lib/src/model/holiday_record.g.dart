// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HolidayRecord _$HolidayRecordFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HolidayRecord',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'date', 'reason'],
        );
        final val = HolidayRecord(
          id: $checkedConvert('id', (v) => v as String),
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$HolidayRecordToJson(HolidayRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'reason': instance.reason,
    };
