//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'personal_entry_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalEntryInput {
  /// Returns a new [PersonalEntryInput] instance.
  PersonalEntryInput({
    required this.contactId,
    required this.direction,
    required this.amountPaise,
    required this.date,
    this.note,
  });

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
  final PersonalEntryInputDirectionEnum direction;

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
  final String date;

  @JsonKey(
    name: r'note',
    required: false,
    includeIfNull: false,
  )
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalEntryInput &&
          other.contactId == contactId &&
          other.direction == direction &&
          other.amountPaise == amountPaise &&
          other.date == date &&
          other.note == note;

  @override
  int get hashCode =>
      contactId.hashCode +
      direction.hashCode +
      amountPaise.hashCode +
      date.hashCode +
      note.hashCode;

  factory PersonalEntryInput.fromJson(Map<String, dynamic> json) =>
      _$PersonalEntryInputFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalEntryInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PersonalEntryInputDirectionEnum {
  @JsonValue(r'GAVE')
  GAVE(r'GAVE'),
  @JsonValue(r'GOT')
  GOT(r'GOT');

  const PersonalEntryInputDirectionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
