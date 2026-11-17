// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_contact_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalContactPatch _$PersonalContactPatchFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalContactPatch',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = PersonalContactPatch(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as String?),
          mobile: $checkedConvert('mobile', (v) => v as String?),
          clearMobile: $checkedConvert('clearMobile', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PersonalContactPatchToJson(
        PersonalContactPatch instance) =>
    <String, dynamic>{
      'version': instance.version,
      if (instance.name case final value?) 'name': value,
      if (instance.mobile case final value?) 'mobile': value,
      if (instance.clearMobile case final value?) 'clearMobile': value,
    };
