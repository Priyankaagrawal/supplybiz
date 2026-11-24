// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_export_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectExportResponse _$SubjectExportResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubjectExportResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['filename', 'json'],
        );
        final val = SubjectExportResponse(
          filename: $checkedConvert('filename', (v) => v as String),
          json: $checkedConvert('json', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubjectExportResponseToJson(
        SubjectExportResponse instance) =>
    <String, dynamic>{
      'filename': instance.filename,
      'json': instance.json,
    };
