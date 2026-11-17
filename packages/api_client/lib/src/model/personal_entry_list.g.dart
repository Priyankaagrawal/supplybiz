// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_entry_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalEntryList _$PersonalEntryListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalEntryList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = PersonalEntryList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      PersonalEntryRecord.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PersonalEntryListToJson(PersonalEntryList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
