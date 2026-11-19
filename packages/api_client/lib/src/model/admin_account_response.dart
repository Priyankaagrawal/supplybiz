//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'admin_account_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminAccountResponse {
  /// Returns a new [AdminAccountResponse] instance.
  AdminAccountResponse({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.totpEnrolled,
    required this.updatedAt,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'email',
    required: true,
    includeIfNull: false,
  )
  final String email;

  @JsonKey(
    name: r'role',
    required: true,
    includeIfNull: false,
  )
  final String role;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'totpEnrolled',
    required: true,
    includeIfNull: false,
  )
  final bool totpEnrolled;

  @JsonKey(
    name: r'updatedAt',
    required: true,
    includeIfNull: false,
  )
  final String updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAccountResponse &&
          other.id == id &&
          other.email == email &&
          other.role == role &&
          other.status == status &&
          other.totpEnrolled == totpEnrolled &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      id.hashCode +
      email.hashCode +
      role.hashCode +
      status.hashCode +
      totpEnrolled.hashCode +
      updatedAt.hashCode;

  factory AdminAccountResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminAccountResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminAccountResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
