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
    this.code,
    this.name,
    this.icon,
    this.type,
    this.sortOrder,
    this.productTypes,
    this.id,
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
    name: r'code',
    required: false,
    includeIfNull: false,
  )
  final String? code;

  @JsonKey(
    name: r'name',
    required: false,
    includeIfNull: false,
  )
  final String? name;

  @JsonKey(
    name: r'icon',
    required: false,
    includeIfNull: false,
  )
  final String? icon;

  @JsonKey(
    name: r'type',
    required: false,
    includeIfNull: false,
  )
  final String? type;

  @JsonKey(
    name: r'sortOrder',
    required: false,
    includeIfNull: false,
  )
  final num? sortOrder;

  @JsonKey(
    name: r'productTypes',
    required: false,
    includeIfNull: false,
  )
  final List<String>? productTypes;

  @JsonKey(
    name: r'id',
    required: false,
    includeIfNull: false,
  )
  final String? id;

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
          other.code == code &&
          other.name == name &&
          other.icon == icon &&
          other.type == type &&
          other.sortOrder == sortOrder &&
          other.productTypes == productTypes &&
          other.id == id &&
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
      code.hashCode +
      name.hashCode +
      (icon == null ? 0 : icon.hashCode) +
      type.hashCode +
      sortOrder.hashCode +
      productTypes.hashCode +
      id.hashCode +
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
