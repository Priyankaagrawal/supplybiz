//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/managed_customer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'managed_customer_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedCustomerList {
  /// Returns a new [ManagedCustomerList] instance.
  ManagedCustomerList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<ManagedCustomer> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedCustomerList &&
          other.items == items &&
          other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory ManagedCustomerList.fromJson(Map<String, dynamic> json) =>
      _$ManagedCustomerListFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedCustomerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
