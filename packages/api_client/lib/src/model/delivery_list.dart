//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/order_detail.dart';
import 'package:supplybiz_api_client/src/model/delivery_counts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delivery_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeliveryList {
  /// Returns a new [DeliveryList] instance.
  DeliveryList({
    required this.serverTime,
    required this.businessDate,
    required this.deliveryDate,
    required this.counts,
    required this.items,
    required this.total,
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
  final String businessDate;

  @JsonKey(
    name: r'deliveryDate',
    required: true,
    includeIfNull: false,
  )
  final String deliveryDate;

  @JsonKey(
    name: r'counts',
    required: true,
    includeIfNull: false,
  )
  final DeliveryCounts counts;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<OrderDetail> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryList &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.deliveryDate == deliveryDate &&
          other.counts == counts &&
          other.items == items &&
          other.total == total;

  @override
  int get hashCode =>
      serverTime.hashCode +
      businessDate.hashCode +
      deliveryDate.hashCode +
      counts.hashCode +
      items.hashCode +
      total.hashCode;

  factory DeliveryList.fromJson(Map<String, dynamic> json) =>
      _$DeliveryListFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
