//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/subscription_customer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_customer_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionCustomerList {
  /// Returns a new [SubscriptionCustomerList] instance.
  SubscriptionCustomerList({
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
  final List<SubscriptionCustomer> items;

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
      other is SubscriptionCustomerList &&
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

  factory SubscriptionCustomerList.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionCustomerListFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionCustomerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
