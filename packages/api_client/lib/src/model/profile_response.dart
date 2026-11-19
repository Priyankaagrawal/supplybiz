//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'profile_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProfileResponse {
  /// Returns a new [ProfileResponse] instance.
  ProfileResponse({
    required this.id,
    required this.mobile,
    required this.name,
    required this.email,
    required this.photoMediaId,
    required this.updatedAt,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  /// Read-only authenticated mobile.
  @JsonKey(
    name: r'mobile',
    required: true,
    includeIfNull: false,
  )
  final String mobile;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: true,
  )
  final String? name;

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

  @JsonKey(
    name: r'updatedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileResponse &&
          other.id == id &&
          other.mobile == mobile &&
          other.name == name &&
          other.email == email &&
          other.photoMediaId == photoMediaId &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      id.hashCode +
      mobile.hashCode +
      (name == null ? 0 : name.hashCode) +
      (email == null ? 0 : email.hashCode) +
      (photoMediaId == null ? 0 : photoMediaId.hashCode) +
      updatedAt.hashCode;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
