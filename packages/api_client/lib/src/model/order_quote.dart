//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/order_priced_line.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_quote.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderQuote {
  /// Returns a new [OrderQuote] instance.
  OrderQuote({
    required this.serverTime,
    required this.businessDate,
    required this.sameDayCutoff,
    required this.items,
    required this.subtotalPaise,
    required this.deliveryChargePaise,
    required this.discountPaise,
    required this.totalPaise,
  });

  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final String serverTime;

  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  /// Vendor-configured IST cutoff, HH:mm:ss; null disables today.
  @JsonKey(
    name: r'sameDayCutoff',
    required: true,
    includeIfNull: true,
  )
  final String? sameDayCutoff;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<OrderPricedLine> items;

  @JsonKey(
    name: r'subtotalPaise',
    required: true,
    includeIfNull: false,
  )
  final String subtotalPaise;

  @JsonKey(
    name: r'deliveryChargePaise',
    required: true,
    includeIfNull: false,
  )
  final String deliveryChargePaise;

  @JsonKey(
    name: r'discountPaise',
    required: true,
    includeIfNull: false,
  )
  final String discountPaise;

  @JsonKey(
    name: r'totalPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderQuote &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.sameDayCutoff == sameDayCutoff &&
          other.items == items &&
          other.subtotalPaise == subtotalPaise &&
          other.deliveryChargePaise == deliveryChargePaise &&
          other.discountPaise == discountPaise &&
          other.totalPaise == totalPaise;

  @override
  int get hashCode =>
      serverTime.hashCode +
      businessDate.hashCode +
      (sameDayCutoff == null ? 0 : sameDayCutoff.hashCode) +
      items.hashCode +
      subtotalPaise.hashCode +
      deliveryChargePaise.hashCode +
      discountPaise.hashCode +
      totalPaise.hashCode;

  factory OrderQuote.fromJson(Map<String, dynamic> json) =>
      _$OrderQuoteFromJson(json);

  Map<String, dynamic> toJson() => _$OrderQuoteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
