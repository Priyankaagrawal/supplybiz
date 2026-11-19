// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_export_created.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportExportCreated _$ReportExportCreatedFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportExportCreated',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['exportId'],
        );
        final val = ReportExportCreated(
          exportId: $checkedConvert('exportId', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportExportCreatedToJson(
        ReportExportCreated instance) =>
    <String, dynamic>{
      'exportId': instance.exportId,
    };
