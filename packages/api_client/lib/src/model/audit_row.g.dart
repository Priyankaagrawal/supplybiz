// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditRow _$AuditRowFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AuditRow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'actor_type',
            'actor_id',
            'action',
            'entity',
            'entity_id',
            'before',
            'after',
            'ip',
            'at'
          ],
        );
        final val = AuditRow(
          id: $checkedConvert('id', (v) => v as String),
          actorType: $checkedConvert('actor_type', (v) => v as String),
          actorId: $checkedConvert('actor_id', (v) => v as String?),
          action: $checkedConvert('action', (v) => v as String),
          entity: $checkedConvert('entity', (v) => v as String),
          entityId: $checkedConvert('entity_id', (v) => v as String?),
          before: $checkedConvert(
              'before',
              (v) => v == null
                  ? null
                  : AuditSnapshot.fromJson(v as Map<String, dynamic>)),
          after: $checkedConvert(
              'after',
              (v) => v == null
                  ? null
                  : AuditSnapshot.fromJson(v as Map<String, dynamic>)),
          ip: $checkedConvert('ip', (v) => v as String?),
          at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'actorType': 'actor_type',
        'actorId': 'actor_id',
        'entityId': 'entity_id'
      },
    );

Map<String, dynamic> _$AuditRowToJson(AuditRow instance) => <String, dynamic>{
      'id': instance.id,
      'actor_type': instance.actorType,
      'actor_id': instance.actorId,
      'action': instance.action,
      'entity': instance.entity,
      'entity_id': instance.entityId,
      'before': instance.before?.toJson(),
      'after': instance.after?.toJson(),
      'ip': instance.ip,
      'at': instance.at.toIso8601String(),
    };
