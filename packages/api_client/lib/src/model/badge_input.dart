//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'badge_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BadgeInput {
  /// Returns a new [BadgeInput] instance.
  BadgeInput({
    required this.reason,
    required this.expectedUpdatedAt,
    required this.badges,
  });

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @JsonKey(
    name: r'expectedUpdatedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime expectedUpdatedAt;

  @JsonKey(
    name: r'badges',
    required: true,
    includeIfNull: false,
  )
  final List<String> badges;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeInput &&
          other.reason == reason &&
          other.expectedUpdatedAt == expectedUpdatedAt &&
          other.badges == badges;

  @override
  int get hashCode =>
      reason.hashCode + expectedUpdatedAt.hashCode + badges.hashCode;

  factory BadgeInput.fromJson(Map<String, dynamic> json) =>
      _$BadgeInputFromJson(json);

  Map<String, dynamic> toJson() => _$BadgeInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
