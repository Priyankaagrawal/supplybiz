// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_contact_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalContactInput _$PersonalContactInputFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalContactInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['name'],
        );
        final val = PersonalContactInput(
          name: $checkedConvert('name', (v) => v as String),
          mobile: $checkedConvert('mobile', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PersonalContactInputToJson(
        PersonalContactInput instance) =>
    <String, dynamic>{
      'name': instance.name,
      if (instance.mobile case final value?) 'mobile': value,
    };
