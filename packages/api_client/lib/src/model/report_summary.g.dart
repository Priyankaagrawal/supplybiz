// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportSummary _$ReportSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportSummary',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'from',
            'to',
            'serverTime',
            'businessDate',
            'totalSalesPaise',
            'totalOrders',
            'deliveredOrders',
            'cancelledOrders',
            'milkSoldLitres',
            'milkSoldUnmeasuredLines',
            'totalEarningsPaise',
            'pendingPaymentsPaise',
            'activeCustomers',
            'productSalesPaise',
            'deliveryChargesPaise',
            'discountPaise',
            'unitemizedSalesPaise'
          ],
        );
        final val = ReportSummary(
          from: $checkedConvert('from', (v) => DateTime.parse(v as String)),
          to: $checkedConvert('to', (v) => DateTime.parse(v as String)),
          serverTime:
              $checkedConvert('serverTime', (v) => DateTime.parse(v as String)),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          totalSalesPaise:
              $checkedConvert('totalSalesPaise', (v) => v as String),
          totalOrders:
              $checkedConvert('totalOrders', (v) => (v as num).toInt()),
          deliveredOrders:
              $checkedConvert('deliveredOrders', (v) => (v as num).toInt()),
          cancelledOrders:
              $checkedConvert('cancelledOrders', (v) => (v as num).toInt()),
          milkSoldLitres: $checkedConvert('milkSoldLitres', (v) => v as String),
          milkSoldUnmeasuredLines: $checkedConvert(
              'milkSoldUnmeasuredLines', (v) => (v as num).toInt()),
          totalEarningsPaise:
              $checkedConvert('totalEarningsPaise', (v) => v as String),
          pendingPaymentsPaise:
              $checkedConvert('pendingPaymentsPaise', (v) => v as String),
          activeCustomers:
              $checkedConvert('activeCustomers', (v) => (v as num).toInt()),
          productSalesPaise:
              $checkedConvert('productSalesPaise', (v) => v as String),
          deliveryChargesPaise:
              $checkedConvert('deliveryChargesPaise', (v) => v as String),
          discountPaise: $checkedConvert('discountPaise', (v) => v as String),
          unitemizedSalesPaise:
              $checkedConvert('unitemizedSalesPaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportSummaryToJson(ReportSummary instance) =>
    <String, dynamic>{
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
      'serverTime': instance.serverTime.toIso8601String(),
      'businessDate': instance.businessDate.toIso8601String(),
      'totalSalesPaise': instance.totalSalesPaise,
      'totalOrders': instance.totalOrders,
      'deliveredOrders': instance.deliveredOrders,
      'cancelledOrders': instance.cancelledOrders,
      'milkSoldLitres': instance.milkSoldLitres,
      'milkSoldUnmeasuredLines': instance.milkSoldUnmeasuredLines,
      'totalEarningsPaise': instance.totalEarningsPaise,
      'pendingPaymentsPaise': instance.pendingPaymentsPaise,
      'activeCustomers': instance.activeCustomers,
      'productSalesPaise': instance.productSalesPaise,
      'deliveryChargesPaise': instance.deliveryChargesPaise,
      'discountPaise': instance.discountPaise,
      'unitemizedSalesPaise': instance.unitemizedSalesPaise,
    };
