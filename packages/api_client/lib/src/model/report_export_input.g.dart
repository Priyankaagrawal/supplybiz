// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_export_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportExportInput _$ReportExportInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportExportInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['from', 'to', 'format'],
        );
        final val = ReportExportInput(
          from: $checkedConvert('from', (v) => v as String),
          to: $checkedConvert('to', (v) => v as String),
          format: $checkedConvert('format',
              (v) => $enumDecode(_$ReportExportInputFormatEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportExportInputToJson(ReportExportInput instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'format': _$ReportExportInputFormatEnumEnumMap[instance.format]!,
    };

const _$ReportExportInputFormatEnumEnumMap = {
  ReportExportInputFormatEnum.CSV: 'CSV',
};
