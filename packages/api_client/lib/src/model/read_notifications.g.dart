// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_notifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadNotifications _$ReadNotificationsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReadNotifications',
      json,
      ($checkedConvert) {
        final val = ReadNotifications(
          role: $checkedConvert(
              'role',
              (v) =>
                  $enumDecodeNullable(_$ReadNotificationsRoleEnumEnumMap, v)),
          ids: $checkedConvert('ids',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          all: $checkedConvert('all', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReadNotificationsToJson(ReadNotifications instance) =>
    <String, dynamic>{
      if (_$ReadNotificationsRoleEnumEnumMap[instance.role] case final value?)
        'role': value,
      if (instance.ids case final value?) 'ids': value,
      if (instance.all case final value?) 'all': value,
    };

const _$ReadNotificationsRoleEnumEnumMap = {
  ReadNotificationsRoleEnum.VENDOR: 'VENDOR',
  ReadNotificationsRoleEnum.CUSTOMER: 'CUSTOMER',
};
