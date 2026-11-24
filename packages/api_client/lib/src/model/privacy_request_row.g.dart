// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_request_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivacyRequestRow _$PrivacyRequestRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PrivacyRequestRow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'userId',
            'kind',
            'status',
            'createdAt',
            'deadline',
            'reason',
            'version'
          ],
        );
        final val = PrivacyRequestRow(
          id: $checkedConvert('id', (v) => v as String),
          userId: $checkedConvert('userId', (v) => v as String),
          kind: $checkedConvert('kind', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
          deadline: $checkedConvert('deadline', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String?),
          version: $checkedConvert('version', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$PrivacyRequestRowToJson(PrivacyRequestRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'kind': instance.kind,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'deadline': instance.deadline,
      'reason': instance.reason,
      'version': instance.version,
    };
