//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/sale_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sale_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaleList {
  /// Returns a new [SaleList] instance.
  SaleList({
    required this.items,
    required this.total,
    required this.serverTime,
    required this.businessDate,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<SaleResponse> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleList &&
          other.items == items &&
          other.total == total &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate;

  @override
  int get hashCode =>
      items.hashCode +
      total.hashCode +
      serverTime.hashCode +
      businessDate.hashCode;

  factory SaleList.fromJson(Map<String, dynamic> json) =>
      _$SaleListFromJson(json);

  Map<String, dynamic> toJson() => _$SaleListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
