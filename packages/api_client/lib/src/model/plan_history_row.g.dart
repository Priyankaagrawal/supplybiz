// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_history_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanHistoryRow _$PlanHistoryRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanHistoryRow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'vendorId',
            'planId',
            'code',
            'startsAt',
            'endsAt',
            'reason',
            'grantedByAdmin',
            'auditId',
            'supersededAt'
          ],
        );
        final val = PlanHistoryRow(
          id: $checkedConvert('id', (v) => v as String),
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          planId: $checkedConvert('planId', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String),
          startsAt:
              $checkedConvert('startsAt', (v) => DateTime.parse(v as String)),
          endsAt: $checkedConvert('endsAt', (v) => DateTime.parse(v as String)),
          reason: $checkedConvert('reason', (v) => v as String),
          grantedByAdmin: $checkedConvert('grantedByAdmin', (v) => v as String),
          auditId: $checkedConvert('auditId', (v) => v as String),
          supersededAt: $checkedConvert('supersededAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanHistoryRowToJson(PlanHistoryRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'planId': instance.planId,
      'code': instance.code,
      'startsAt': instance.startsAt.toIso8601String(),
      'endsAt': instance.endsAt.toIso8601String(),
      'reason': instance.reason,
      'grantedByAdmin': instance.grantedByAdmin,
      'auditId': instance.auditId,
      'supersededAt': instance.supersededAt?.toIso8601String(),
    };
