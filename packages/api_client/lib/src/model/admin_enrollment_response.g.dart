// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_enrollment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminEnrollmentResponse _$AdminEnrollmentResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminEnrollmentResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['enrollmentSecret'],
        );
        final val = AdminEnrollmentResponse(
          enrollmentSecret:
              $checkedConvert('enrollmentSecret', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$AdminEnrollmentResponseToJson(
        AdminEnrollmentResponse instance) =>
    <String, dynamic>{
      'enrollmentSecret': instance.enrollmentSecret,
    };
