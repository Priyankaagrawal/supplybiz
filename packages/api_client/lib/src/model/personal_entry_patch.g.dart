// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_entry_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalEntryPatch _$PersonalEntryPatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalEntryPatch',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version'],
        );
        final val = PersonalEntryPatch(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          contactId: $checkedConvert('contactId', (v) => v as String?),
          direction: $checkedConvert(
              'direction',
              (v) => $enumDecodeNullable(
                  _$PersonalEntryPatchDirectionEnumEnumMap, v)),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String?),
          date: $checkedConvert('date', (v) => v as String?),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PersonalEntryPatchToJson(PersonalEntryPatch instance) =>
    <String, dynamic>{
      'version': instance.version,
      if (instance.contactId case final value?) 'contactId': value,
      if (_$PersonalEntryPatchDirectionEnumEnumMap[instance.direction]
          case final value?)
        'direction': value,
      if (instance.amountPaise case final value?) 'amountPaise': value,
      if (instance.date case final value?) 'date': value,
      if (instance.note case final value?) 'note': value,
    };

const _$PersonalEntryPatchDirectionEnumEnumMap = {
  PersonalEntryPatchDirectionEnum.GAVE: 'GAVE',
  PersonalEntryPatchDirectionEnum.GOT: 'GOT',
};
