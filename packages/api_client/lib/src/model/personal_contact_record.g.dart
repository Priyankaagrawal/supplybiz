// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_contact_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalContactRecord _$PersonalContactRecordFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalContactRecord',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'version',
            'name',
            'mobile',
            'balancePaise'
          ],
        );
        final val = PersonalContactRecord(
          id: $checkedConvert('id', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as String),
          mobile: $checkedConvert('mobile', (v) => v as String?),
          balancePaise: $checkedConvert('balancePaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PersonalContactRecordToJson(
        PersonalContactRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'name': instance.name,
      'mobile': instance.mobile,
      'balancePaise': instance.balancePaise,
    };
