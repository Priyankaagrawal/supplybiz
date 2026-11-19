// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_products.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportProducts _$ReportProductsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportProducts',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'from',
            'to',
            'serverTime',
            'businessDate',
            'items',
            'total',
            'totalProductSalesPaise'
          ],
        );
        final val = ReportProducts(
          from: $checkedConvert('from', (v) => DateTime.parse(v as String)),
          to: $checkedConvert('to', (v) => DateTime.parse(v as String)),
          serverTime:
              $checkedConvert('serverTime', (v) => DateTime.parse(v as String)),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => ReportProduct.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          totalProductSalesPaise:
              $checkedConvert('totalProductSalesPaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportProductsToJson(ReportProducts instance) =>
    <String, dynamic>{
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
      'serverTime': instance.serverTime.toIso8601String(),
      'businessDate': instance.businessDate.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'totalProductSalesPaise': instance.totalProductSalesPaise,
    };
