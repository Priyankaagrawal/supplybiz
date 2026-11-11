// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentResponse _$AssignmentResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AssignmentResponse',
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
            'auditId'
          ],
        );
        final val = AssignmentResponse(
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
        );
        return val;
      },
    );

Map<String, dynamic> _$AssignmentResponseToJson(AssignmentResponse instance) =>
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
    };
