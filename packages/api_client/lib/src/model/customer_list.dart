//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/customer_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerList {
  /// Returns a new [CustomerList] instance.
  CustomerList({
    required this.items,
    required this.total,
    required this.activeCount,
    required this.customerLimit,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<CustomerResponse> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @JsonKey(
    name: r'activeCount',
    required: true,
    includeIfNull: false,
  )
  final int activeCount;

  @JsonKey(
    name: r'customerLimit',
    required: true,
    includeIfNull: false,
  )
  final int customerLimit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerList &&
          other.items == items &&
          other.total == total &&
          other.activeCount == activeCount &&
          other.customerLimit == customerLimit;

  @override
  int get hashCode =>
      items.hashCode +
      total.hashCode +
      activeCount.hashCode +
      customerLimit.hashCode;

  factory CustomerList.fromJson(Map<String, dynamic> json) =>
      _$CustomerListFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
