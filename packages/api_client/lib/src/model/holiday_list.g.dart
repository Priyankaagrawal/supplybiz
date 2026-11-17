// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HolidayList _$HolidayListFromJson(Map<String, dynamic> json) => $checkedCreate(
      'HolidayList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total', 'serverTime', 'businessDate'],
        );
        final val = HolidayList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => HolidayRecord.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$HolidayListToJson(HolidayList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
    };
