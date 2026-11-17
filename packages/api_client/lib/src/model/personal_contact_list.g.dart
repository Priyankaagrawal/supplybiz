// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_contact_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalContactList _$PersonalContactListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalContactList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = PersonalContactList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      PersonalContactRecord.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PersonalContactListToJson(
        PersonalContactList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
