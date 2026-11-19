// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_export_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportExportStatus _$ReportExportStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportExportStatus',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'exportId',
            'status',
            'from',
            'to',
            'createdAt',
            'expiresAt',
            'format',
            'sizeBytes',
            'sha256',
            'downloadPath'
          ],
        );
        final val = ReportExportStatus(
          exportId: $checkedConvert('exportId', (v) => v as String),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$ReportExportStatusStatusEnumEnumMap, v)),
          from: $checkedConvert('from', (v) => DateTime.parse(v as String)),
          to: $checkedConvert('to', (v) => DateTime.parse(v as String)),
          createdAt:
              $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
          expiresAt:
              $checkedConvert('expiresAt', (v) => DateTime.parse(v as String)),
          format: $checkedConvert('format',
              (v) => $enumDecode(_$ReportExportStatusFormatEnumEnumMap, v)),
          sizeBytes: $checkedConvert('sizeBytes', (v) => (v as num).toInt()),
          sha256: $checkedConvert('sha256', (v) => v as String),
          downloadPath: $checkedConvert('downloadPath', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportExportStatusToJson(ReportExportStatus instance) =>
    <String, dynamic>{
      'exportId': instance.exportId,
      'status': _$ReportExportStatusStatusEnumEnumMap[instance.status]!,
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'format': _$ReportExportStatusFormatEnumEnumMap[instance.format]!,
      'sizeBytes': instance.sizeBytes,
      'sha256': instance.sha256,
      'downloadPath': instance.downloadPath,
    };

const _$ReportExportStatusStatusEnumEnumMap = {
  ReportExportStatusStatusEnum.READY: 'READY',
  ReportExportStatusStatusEnum.EXPIRED: 'EXPIRED',
};

const _$ReportExportStatusFormatEnumEnumMap = {
  ReportExportStatusFormatEnum.CSV: 'CSV',
};
