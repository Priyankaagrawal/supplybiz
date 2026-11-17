//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'personal_entry_patch.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalEntryPatch {
  /// Returns a new [PersonalEntryPatch] instance.
  PersonalEntryPatch({
    required this.version,
    this.contactId,
    this.direction,
    this.amountPaise,
    this.date,
    this.note,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'contactId',
    required: false,
    includeIfNull: false,
  )
  final String? contactId;

  @JsonKey(
    name: r'direction',
    required: false,
    includeIfNull: false,
  )
  final PersonalEntryPatchDirectionEnum? direction;

  @JsonKey(
    name: r'amountPaise',
    required: false,
    includeIfNull: false,
  )
  final String? amountPaise;

  @JsonKey(
    name: r'date',
    required: false,
    includeIfNull: false,
  )
  final String? date;

  @JsonKey(
    name: r'note',
    required: false,
    includeIfNull: false,
  )
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalEntryPatch &&
          other.version == version &&
          other.contactId == contactId &&
          other.direction == direction &&
          other.amountPaise == amountPaise &&
          other.date == date &&
          other.note == note;

  @override
  int get hashCode =>
      version.hashCode +
      contactId.hashCode +
      direction.hashCode +
      amountPaise.hashCode +
      date.hashCode +
      note.hashCode;

  factory PersonalEntryPatch.fromJson(Map<String, dynamic> json) =>
      _$PersonalEntryPatchFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalEntryPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PersonalEntryPatchDirectionEnum {
  @JsonValue(r'GAVE')
  GAVE(r'GAVE'),
  @JsonValue(r'GOT')
  GOT(r'GOT');

  const PersonalEntryPatchDirectionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
