// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_export_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlatformExportResponse _$PlatformExportResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PlatformExportResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['filename', 'csv', 'snapshotAt'],
        );
        final val = PlatformExportResponse(
          filename: $checkedConvert('filename', (v) => v as String),
          csv: $checkedConvert('csv', (v) => v as String),
          snapshotAt: $checkedConvert('snapshotAt', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlatformExportResponseToJson(
        PlatformExportResponse instance) =>
    <String, dynamic>{
      'filename': instance.filename,
      'csv': instance.csv,
      'snapshotAt': instance.snapshotAt,
    };
