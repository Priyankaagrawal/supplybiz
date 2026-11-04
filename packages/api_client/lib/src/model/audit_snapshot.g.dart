// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditSnapshot _$AuditSnapshotFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AuditSnapshot',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'role',
            'status',
            'failed_attempts',
            'locked_until',
            'last_login_at',
            'totp_enrolled'
          ],
        );
        final val = AuditSnapshot(
          role: $checkedConvert('role', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          failedAttempts: $checkedConvert('failed_attempts', (v) => v as num),
          lockedUntil: $checkedConvert('locked_until',
              (v) => v == null ? null : DateTime.parse(v as String)),
          lastLoginAt: $checkedConvert('last_login_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          totpEnrolled: $checkedConvert('totp_enrolled', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'failedAttempts': 'failed_attempts',
        'lockedUntil': 'locked_until',
        'lastLoginAt': 'last_login_at',
        'totpEnrolled': 'totp_enrolled'
      },
    );

Map<String, dynamic> _$AuditSnapshotToJson(AuditSnapshot instance) =>
    <String, dynamic>{
      'role': instance.role,
      'status': instance.status,
      'failed_attempts': instance.failedAttempts,
      'locked_until': instance.lockedUntil?.toIso8601String(),
      'last_login_at': instance.lastLoginAt?.toIso8601String(),
      'totp_enrolled': instance.totpEnrolled,
    };
