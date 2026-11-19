//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'profile_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProfileInput {
  /// Returns a new [ProfileInput] instance.
  ProfileInput({
    required this.expectedUpdatedAt,
    required this.name,
    required this.email,
    required this.photoMediaId,
  });

  @JsonKey(
    name: r'expectedUpdatedAt',
    required: true,
    includeIfNull: false,
  )
  final String expectedUpdatedAt;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  /// Contact email only; not verified by this operation.
  @JsonKey(
    name: r'email',
    required: true,
    includeIfNull: true,
  )
  final String? email;

  @JsonKey(
    name: r'photoMediaId',
    required: true,
    includeIfNull: true,
  )
  final String? photoMediaId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileInput &&
          other.expectedUpdatedAt == expectedUpdatedAt &&
          other.name == name &&
          other.email == email &&
          other.photoMediaId == photoMediaId;

  @override
  int get hashCode =>
      expectedUpdatedAt.hashCode +
      name.hashCode +
      (email == null ? 0 : email.hashCode) +
      (photoMediaId == null ? 0 : photoMediaId.hashCode);

  factory ProfileInput.fromJson(Map<String, dynamic> json) =>
      _$ProfileInputFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
