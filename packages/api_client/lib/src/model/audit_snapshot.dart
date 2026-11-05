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
    this.role,
    this.status,
    this.failedAttempts,
    this.lockedUntil,
    this.lastLoginAt,
    this.totpEnrolled,
    this.verificationMethod,
    this.providerChecks,
    this.reviewerId,
  });

  @JsonKey(
    name: r'role',
    required: false,
    includeIfNull: false,
  )
  final String? role;

  @JsonKey(
    name: r'status',
    required: false,
    includeIfNull: false,
  )
  final String? status;

  @JsonKey(
    name: r'failed_attempts',
    required: false,
    includeIfNull: false,
  )
  final num? failedAttempts;

  @JsonKey(
    name: r'locked_until',
    required: false,
    includeIfNull: false,
  )
  final DateTime? lockedUntil;

  @JsonKey(
    name: r'last_login_at',
    required: false,
    includeIfNull: false,
  )
  final DateTime? lastLoginAt;

  @JsonKey(
    name: r'totp_enrolled',
    required: false,
    includeIfNull: false,
  )
  final bool? totpEnrolled;

  @JsonKey(
    name: r'verificationMethod',
    required: false,
    includeIfNull: false,
  )
  final String? verificationMethod;

  @JsonKey(
    name: r'providerChecks',
    required: false,
    includeIfNull: false,
  )
  final String? providerChecks;

  @JsonKey(
    name: r'reviewerId',
    required: false,
    includeIfNull: false,
  )
  final String? reviewerId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditSnapshot &&
          other.role == role &&
          other.status == status &&
          other.failedAttempts == failedAttempts &&
          other.lockedUntil == lockedUntil &&
          other.lastLoginAt == lastLoginAt &&
          other.totpEnrolled == totpEnrolled &&
          other.verificationMethod == verificationMethod &&
          other.providerChecks == providerChecks &&
          other.reviewerId == reviewerId;

  @override
  int get hashCode =>
      role.hashCode +
      status.hashCode +
      failedAttempts.hashCode +
      (lockedUntil == null ? 0 : lockedUntil.hashCode) +
      (lastLoginAt == null ? 0 : lastLoginAt.hashCode) +
      totpEnrolled.hashCode +
      verificationMethod.hashCode +
      providerChecks.hashCode +
      (reviewerId == null ? 0 : reviewerId.hashCode);

  factory AuditSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AuditSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$AuditSnapshotToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
