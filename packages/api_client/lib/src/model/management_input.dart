//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'management_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagementInput {
  /// Returns a new [ManagementInput] instance.
  ManagementInput({
    required this.reason,
    required this.expectedUpdatedAt,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagementInput &&
          other.reason == reason &&
          other.expectedUpdatedAt == expectedUpdatedAt;

  @override
  int get hashCode => reason.hashCode + expectedUpdatedAt.hashCode;

  factory ManagementInput.fromJson(Map<String, dynamic> json) =>
      _$ManagementInputFromJson(json);

  Map<String, dynamic> toJson() => _$ManagementInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
