// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_assignment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorAssignmentResponse _$VendorAssignmentResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorAssignmentResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'planId', 'code', 'startsAt', 'endsAt'],
        );
        final val = VendorAssignmentResponse(
          id: $checkedConvert('id', (v) => v as String),
          planId: $checkedConvert('planId', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String),
          startsAt:
              $checkedConvert('startsAt', (v) => DateTime.parse(v as String)),
          endsAt: $checkedConvert('endsAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorAssignmentResponseToJson(
        VendorAssignmentResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'planId': instance.planId,
      'code': instance.code,
      'startsAt': instance.startsAt.toIso8601String(),
      'endsAt': instance.endsAt.toIso8601String(),
    };
