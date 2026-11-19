//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'change_admin_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChangeAdminInput {
  /// Returns a new [ChangeAdminInput] instance.
  ChangeAdminInput({
    required this.role,
    required this.status,
    required this.expectedUpdatedAt,
    required this.reason,
  });

  @JsonKey(
    name: r'role',
    required: true,
    includeIfNull: false,
  )
  final ChangeAdminInputRoleEnum role;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final ChangeAdminInputStatusEnum status;

  @JsonKey(
    name: r'expectedUpdatedAt',
    required: true,
    includeIfNull: false,
  )
  final String expectedUpdatedAt;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeAdminInput &&
          other.role == role &&
          other.status == status &&
          other.expectedUpdatedAt == expectedUpdatedAt &&
          other.reason == reason;

  @override
  int get hashCode =>
      role.hashCode +
      status.hashCode +
      expectedUpdatedAt.hashCode +
      reason.hashCode;

  factory ChangeAdminInput.fromJson(Map<String, dynamic> json) =>
      _$ChangeAdminInputFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeAdminInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ChangeAdminInputRoleEnum {
  @JsonValue(r'SUPER_ADMIN')
  SUPER_ADMIN(r'SUPER_ADMIN'),
  @JsonValue(r'OPS')
  OPS(r'OPS'),
  @JsonValue(r'SUPPORT')
  SUPPORT(r'SUPPORT'),
  @JsonValue(r'FINANCE')
  FINANCE(r'FINANCE');

  const ChangeAdminInputRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ChangeAdminInputStatusEnum {
  @JsonValue(r'ACTIVE')
  ACTIVE(r'ACTIVE'),
  @JsonValue(r'DISABLED')
  DISABLED(r'DISABLED');

  const ChangeAdminInputStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
