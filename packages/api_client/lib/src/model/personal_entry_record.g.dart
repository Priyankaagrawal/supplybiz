// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_entry_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalEntryRecord _$PersonalEntryRecordFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalEntryRecord',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'version',
            'contactId',
            'direction',
            'amountPaise',
            'date',
            'note'
          ],
        );
        final val = PersonalEntryRecord(
          id: $checkedConvert('id', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          contactId: $checkedConvert('contactId', (v) => v as String),
          direction: $checkedConvert('direction',
              (v) => $enumDecode(_$PersonalEntryRecordDirectionEnumEnumMap, v)),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          note: $checkedConvert('note', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PersonalEntryRecordToJson(
        PersonalEntryRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'contactId': instance.contactId,
      'direction':
          _$PersonalEntryRecordDirectionEnumEnumMap[instance.direction]!,
      'amountPaise': instance.amountPaise,
      'date': instance.date.toIso8601String(),
      'note': instance.note,
    };

const _$PersonalEntryRecordDirectionEnumEnumMap = {
  PersonalEntryRecordDirectionEnum.GAVE: 'GAVE',
  PersonalEntryRecordDirectionEnum.GOT: 'GOT',
};
