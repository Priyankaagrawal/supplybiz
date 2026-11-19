//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_admin_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateAdminInput {
  /// Returns a new [CreateAdminInput] instance.
  CreateAdminInput({
    required this.email,
    required this.password,
    required this.role,
    required this.reason,
  });

  @JsonKey(
    name: r'email',
    required: true,
    includeIfNull: false,
  )
  final String email;

  @JsonKey(
    name: r'password',
    required: true,
    includeIfNull: false,
  )
  final String password;

  @JsonKey(
    name: r'role',
    required: true,
    includeIfNull: false,
  )
  final CreateAdminInputRoleEnum role;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateAdminInput &&
          other.email == email &&
          other.password == password &&
          other.role == role &&
          other.reason == reason;

  @override
  int get hashCode =>
      email.hashCode + password.hashCode + role.hashCode + reason.hashCode;

  factory CreateAdminInput.fromJson(Map<String, dynamic> json) =>
      _$CreateAdminInputFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAdminInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CreateAdminInputRoleEnum {
  @JsonValue(r'SUPER_ADMIN')
  SUPER_ADMIN(r'SUPER_ADMIN'),
  @JsonValue(r'OPS')
  OPS(r'OPS'),
  @JsonValue(r'SUPPORT')
  SUPPORT(r'SUPPORT'),
  @JsonValue(r'FINANCE')
  FINANCE(r'FINANCE');

  const CreateAdminInputRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
