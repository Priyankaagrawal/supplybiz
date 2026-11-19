// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_sales_bucket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportSalesBucket _$ReportSalesBucketFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportSalesBucket',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['from', 'to', 'salesPaise'],
        );
        final val = ReportSalesBucket(
          from: $checkedConvert('from', (v) => DateTime.parse(v as String)),
          to: $checkedConvert('to', (v) => DateTime.parse(v as String)),
          salesPaise: $checkedConvert('salesPaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportSalesBucketToJson(ReportSalesBucket instance) =>
    <String, dynamic>{
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
      'salesPaise': instance.salesPaise,
    };
