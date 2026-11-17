//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'holiday_record.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HolidayRecord {
  /// Returns a new [HolidayRecord] instance.
  HolidayRecord({
    required this.id,
    required this.date,
    required this.reason,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'date',
    required: true,
    includeIfNull: false,
  )
  final DateTime date;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HolidayRecord &&
          other.id == id &&
          other.date == date &&
          other.reason == reason;

  @override
  int get hashCode => id.hashCode + date.hashCode + reason.hashCode;

  factory HolidayRecord.fromJson(Map<String, dynamic> json) =>
      _$HolidayRecordFromJson(json);

  Map<String, dynamic> toJson() => _$HolidayRecordToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
