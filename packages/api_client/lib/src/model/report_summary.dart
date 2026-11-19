//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'report_summary.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportSummary {
  /// Returns a new [ReportSummary] instance.
  ReportSummary({
    required this.from,
    required this.to,
    required this.serverTime,
    required this.businessDate,
    required this.totalSalesPaise,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.milkSoldLitres,
    required this.milkSoldUnmeasuredLines,
    required this.totalEarningsPaise,
    required this.pendingPaymentsPaise,
    required this.activeCustomers,
    required this.productSalesPaise,
    required this.deliveryChargesPaise,
    required this.discountPaise,
    required this.unitemizedSalesPaise,
  });

  @JsonKey(
    name: r'from',
    required: true,
    includeIfNull: false,
  )
  final DateTime from;

  @JsonKey(
    name: r'to',
    required: true,
    includeIfNull: false,
  )
  final DateTime to;

  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final DateTime serverTime;

  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  /// Gross delivered-order totals plus POS totals on actual completion/sale dates. Includes charges; not receipts.
  @JsonKey(
    name: r'totalSalesPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalSalesPaise;

  /// Retained orders scheduled in range; POS is not an order.
  // minimum: 0
  @JsonKey(
    name: r'totalOrders',
    required: true,
    includeIfNull: false,
  )
  final int totalOrders;

  /// Scheduled-in-range orders now DELIVERED.
  // minimum: 0
  @JsonKey(
    name: r'deliveredOrders',
    required: true,
    includeIfNull: false,
  )
  final int deliveredOrders;

  /// Scheduled-in-range orders now CANCELLED; excludes REJECTED/FAILED.
  // minimum: 0
  @JsonKey(
    name: r'cancelledOrders',
    required: true,
    includeIfNull: false,
  )
  final int cancelledOrders;

  /// Known milk litres from immutable delivered/POS line snapshots in actual completion/sale range.
  @JsonKey(
    name: r'milkSoldLitres',
    required: true,
    includeIfNull: false,
  )
  final String milkSoldLitres;

  /// Legacy zero-volume/unknown-classification or non-volume milk lines. Milk total is incomplete when nonzero; never infer history from current catalog.
  // minimum: 0
  @JsonKey(
    name: r'milkSoldUnmeasuredLines',
    required: true,
    includeIfNull: false,
  )
  final int milkSoldUnmeasuredLines;

  /// Net external receipts by ledger value date: payment/POS/confirmed-claim credit roots and reversal chains, plus paid walk-ins once. Opening credits excluded. May be negative for corrections.
  @JsonKey(
    name: r'totalEarningsPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalEarningsPaise;

  /// Current positive Khata due summed per customer, including archived/inactive links, as of serverTime; independent of date range.
  @JsonKey(
    name: r'pendingPaymentsPaise',
    required: true,
    includeIfNull: false,
  )
  final String pendingPaymentsPaise;

  /// Current ACTIVE non-deleted customer links; independent of range.
  // minimum: 0
  @JsonKey(
    name: r'activeCustomers',
    required: true,
    includeIfNull: false,
  )
  final int activeCustomers;

  /// Range item sales excluding delivery charges; matches complete product table total.
  @JsonKey(
    name: r'productSalesPaise',
    required: true,
    includeIfNull: false,
  )
  final String productSalesPaise;

  @JsonKey(
    name: r'deliveryChargesPaise',
    required: true,
    includeIfNull: false,
  )
  final String deliveryChargesPaise;

  /// Stored order discounts; zero under current scope.
  @JsonKey(
    name: r'discountPaise',
    required: true,
    includeIfNull: false,
  )
  final String discountPaise;

  /// Legacy missing/inconsistent item subtotal gap. Sales = products + charges - discounts + this gap.
  @JsonKey(
    name: r'unitemizedSalesPaise',
    required: true,
    includeIfNull: false,
  )
  final String unitemizedSalesPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportSummary &&
          other.from == from &&
          other.to == to &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.totalSalesPaise == totalSalesPaise &&
          other.totalOrders == totalOrders &&
          other.deliveredOrders == deliveredOrders &&
          other.cancelledOrders == cancelledOrders &&
          other.milkSoldLitres == milkSoldLitres &&
          other.milkSoldUnmeasuredLines == milkSoldUnmeasuredLines &&
          other.totalEarningsPaise == totalEarningsPaise &&
          other.pendingPaymentsPaise == pendingPaymentsPaise &&
          other.activeCustomers == activeCustomers &&
          other.productSalesPaise == productSalesPaise &&
          other.deliveryChargesPaise == deliveryChargesPaise &&
          other.discountPaise == discountPaise &&
          other.unitemizedSalesPaise == unitemizedSalesPaise;

  @override
  int get hashCode =>
      from.hashCode +
      to.hashCode +
      serverTime.hashCode +
      businessDate.hashCode +
      totalSalesPaise.hashCode +
      totalOrders.hashCode +
      deliveredOrders.hashCode +
      cancelledOrders.hashCode +
      milkSoldLitres.hashCode +
      milkSoldUnmeasuredLines.hashCode +
      totalEarningsPaise.hashCode +
      pendingPaymentsPaise.hashCode +
      activeCustomers.hashCode +
      productSalesPaise.hashCode +
      deliveryChargesPaise.hashCode +
      discountPaise.hashCode +
      unitemizedSalesPaise.hashCode;

  factory ReportSummary.fromJson(Map<String, dynamic> json) =>
      _$ReportSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ReportSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
