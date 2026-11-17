//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'personal_entry_record.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalEntryRecord {
  /// Returns a new [PersonalEntryRecord] instance.
  PersonalEntryRecord({
    required this.id,
    required this.version,
    required this.contactId,
    required this.direction,
    required this.amountPaise,
    required this.date,
    required this.note,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'contactId',
    required: true,
    includeIfNull: false,
  )
  final String contactId;

  @JsonKey(
    name: r'direction',
    required: true,
    includeIfNull: false,
  )
  final PersonalEntryRecordDirectionEnum direction;

  @JsonKey(
    name: r'amountPaise',
    required: true,
    includeIfNull: false,
  )
  final String amountPaise;

  @JsonKey(
    name: r'date',
    required: true,
    includeIfNull: false,
  )
  final DateTime date;

  @JsonKey(
    name: r'note',
    required: true,
    includeIfNull: false,
  )
  final String note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalEntryRecord &&
          other.id == id &&
          other.version == version &&
          other.contactId == contactId &&
          other.direction == direction &&
          other.amountPaise == amountPaise &&
          other.date == date &&
          other.note == note;

  @override
  int get hashCode =>
      id.hashCode +
      version.hashCode +
      contactId.hashCode +
      direction.hashCode +
      amountPaise.hashCode +
      date.hashCode +
      note.hashCode;

  factory PersonalEntryRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalEntryRecordFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalEntryRecordToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PersonalEntryRecordDirectionEnum {
  @JsonValue(r'GAVE')
  GAVE(r'GAVE'),
  @JsonValue(r'GOT')
  GOT(r'GOT');

  const PersonalEntryRecordDirectionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
