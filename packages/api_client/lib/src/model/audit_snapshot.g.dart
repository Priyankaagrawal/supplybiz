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
        final val = AuditSnapshot(
          code: $checkedConvert('code', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String?),
          icon: $checkedConvert('icon', (v) => v as String?),
          type: $checkedConvert('type', (v) => v as String?),
          sortOrder: $checkedConvert('sortOrder', (v) => v as num?),
          productTypes: $checkedConvert('productTypes',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          id: $checkedConvert('id', (v) => v as String?),
          role: $checkedConvert('role', (v) => v as String?),
          status: $checkedConvert('status', (v) => v as String?),
          failedAttempts: $checkedConvert('failed_attempts', (v) => v as num?),
          lockedUntil: $checkedConvert('locked_until',
              (v) => v == null ? null : DateTime.parse(v as String)),
          lastLoginAt: $checkedConvert('last_login_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          totpEnrolled: $checkedConvert('totp_enrolled', (v) => v as bool?),
          verificationMethod:
              $checkedConvert('verificationMethod', (v) => v as String?),
          providerChecks:
              $checkedConvert('providerChecks', (v) => v as String?),
          reviewerId: $checkedConvert('reviewerId', (v) => v as String?),
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
      if (instance.code case final value?) 'code': value,
      if (instance.name case final value?) 'name': value,
      if (instance.icon case final value?) 'icon': value,
      if (instance.type case final value?) 'type': value,
      if (instance.sortOrder case final value?) 'sortOrder': value,
      if (instance.productTypes case final value?) 'productTypes': value,
      if (instance.id case final value?) 'id': value,
      if (instance.role case final value?) 'role': value,
      if (instance.status case final value?) 'status': value,
      if (instance.failedAttempts case final value?) 'failed_attempts': value,
      if (instance.lockedUntil?.toIso8601String() case final value?)
        'locked_until': value,
      if (instance.lastLoginAt?.toIso8601String() case final value?)
        'last_login_at': value,
      if (instance.totpEnrolled case final value?) 'totp_enrolled': value,
      if (instance.verificationMethod case final value?)
        'verificationMethod': value,
      if (instance.providerChecks case final value?) 'providerChecks': value,
      if (instance.reviewerId case final value?) 'reviewerId': value,
    };
