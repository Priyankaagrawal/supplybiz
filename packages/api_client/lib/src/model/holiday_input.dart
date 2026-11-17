//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'holiday_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HolidayInput {
  /// Returns a new [HolidayInput] instance.
  HolidayInput({
    required this.date,
    required this.reason,
  });

  /// IST calendar date YYYY-MM-DD; deliberately string-valued for exact client serialization.
  @JsonKey(
    name: r'date',
    required: true,
    includeIfNull: false,
  )
  final String date;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HolidayInput && other.date == date && other.reason == reason;

  @override
  int get hashCode => date.hashCode + reason.hashCode;

  factory HolidayInput.fromJson(Map<String, dynamic> json) =>
      _$HolidayInputFromJson(json);

  Map<String, dynamic> toJson() => _$HolidayInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
