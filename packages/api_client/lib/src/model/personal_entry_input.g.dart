// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_entry_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalEntryInput _$PersonalEntryInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalEntryInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['contactId', 'direction', 'amountPaise', 'date'],
        );
        final val = PersonalEntryInput(
          contactId: $checkedConvert('contactId', (v) => v as String),
          direction: $checkedConvert('direction',
              (v) => $enumDecode(_$PersonalEntryInputDirectionEnumEnumMap, v)),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          date: $checkedConvert('date', (v) => v as String),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PersonalEntryInputToJson(PersonalEntryInput instance) =>
    <String, dynamic>{
      'contactId': instance.contactId,
      'direction':
          _$PersonalEntryInputDirectionEnumEnumMap[instance.direction]!,
      'amountPaise': instance.amountPaise,
      'date': instance.date,
      if (instance.note case final value?) 'note': value,
    };

const _$PersonalEntryInputDirectionEnumEnumMap = {
  PersonalEntryInputDirectionEnum.GAVE: 'GAVE',
  PersonalEntryInputDirectionEnum.GOT: 'GOT',
};
