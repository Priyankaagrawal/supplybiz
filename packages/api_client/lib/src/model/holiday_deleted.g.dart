// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_deleted.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HolidayDeleted _$HolidayDeletedFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HolidayDeleted',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'deleted'],
        );
        final val = HolidayDeleted(
          id: $checkedConvert('id', (v) => v as String),
          deleted: $checkedConvert('deleted', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$HolidayDeletedToJson(HolidayDeleted instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deleted': instance.deleted,
    };
