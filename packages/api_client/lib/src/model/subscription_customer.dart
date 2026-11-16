//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_customer.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionCustomer {
  /// Returns a new [SubscriptionCustomer] instance.
  SubscriptionCustomer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.status,
    required this.activeSubscriptions,
    required this.pausedSubscriptions,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'mobile',
    required: true,
    includeIfNull: false,
  )
  final String mobile;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'activeSubscriptions',
    required: true,
    includeIfNull: false,
  )
  final int activeSubscriptions;

  @JsonKey(
    name: r'pausedSubscriptions',
    required: true,
    includeIfNull: false,
  )
  final int pausedSubscriptions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionCustomer &&
          other.id == id &&
          other.name == name &&
          other.mobile == mobile &&
          other.status == status &&
          other.activeSubscriptions == activeSubscriptions &&
          other.pausedSubscriptions == pausedSubscriptions;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      mobile.hashCode +
      status.hashCode +
      activeSubscriptions.hashCode +
      pausedSubscriptions.hashCode;

  factory SubscriptionCustomer.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionCustomerFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionCustomerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
