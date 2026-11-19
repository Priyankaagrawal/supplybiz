//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/report_product.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_products.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportProducts {
  /// Returns a new [ReportProducts] instance.
  ReportProducts({
    required this.from,
    required this.to,
    required this.serverTime,
    required this.businessDate,
    required this.items,
    required this.total,
    required this.totalProductSalesPaise,
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

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<ReportProduct> items;

  // minimum: 0
  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  /// All product snapshot groups across the range, not just the current page.
  @JsonKey(
    name: r'totalProductSalesPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalProductSalesPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportProducts &&
          other.from == from &&
          other.to == to &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.items == items &&
          other.total == total &&
          other.totalProductSalesPaise == totalProductSalesPaise;

  @override
  int get hashCode =>
      from.hashCode +
      to.hashCode +
      serverTime.hashCode +
      businessDate.hashCode +
      items.hashCode +
      total.hashCode +
      totalProductSalesPaise.hashCode;

  factory ReportProducts.fromJson(Map<String, dynamic> json) =>
      _$ReportProductsFromJson(json);

  Map<String, dynamic> toJson() => _$ReportProductsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
