//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'audit_snapshot.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuditSnapshot {
  /// Returns a new [AuditSnapshot] instance.
  AuditSnapshot({
    required this.role,
    required this.status,
    required this.failedAttempts,
    required this.lockedUntil,
    required this.lastLoginAt,
    required this.totpEnrolled,
  });

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
    name: r'failed_attempts',
    required: true,
    includeIfNull: false,
  )
  final num failedAttempts;

  @JsonKey(
    name: r'locked_until',
    required: true,
    includeIfNull: true,
  )
  final DateTime? lockedUntil;

  @JsonKey(
    name: r'last_login_at',
    required: true,
    includeIfNull: true,
  )
  final DateTime? lastLoginAt;

  @JsonKey(
    name: r'totp_enrolled',
    required: true,
    includeIfNull: false,
  )
  final bool totpEnrolled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditSnapshot &&
          other.role == role &&
          other.status == status &&
          other.failedAttempts == failedAttempts &&
          other.lockedUntil == lockedUntil &&
          other.lastLoginAt == lastLoginAt &&
          other.totpEnrolled == totpEnrolled;

  @override
  int get hashCode =>
      role.hashCode +
      status.hashCode +
      failedAttempts.hashCode +
      (lockedUntil == null ? 0 : lockedUntil.hashCode) +
      (lastLoginAt == null ? 0 : lastLoginAt.hashCode) +
      totpEnrolled.hashCode;

  factory AuditSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AuditSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$AuditSnapshotToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
