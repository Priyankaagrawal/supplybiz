//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_delivery.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionDelivery {
  /// Returns a new [SubscriptionDelivery] instance.
  SubscriptionDelivery({
    required this.orderId,
    required this.deliveryDate,
    required this.productName,
    required this.qty,
    required this.amountPaise,
    required this.paymentStatus,
  });

  @JsonKey(
    name: r'orderId',
    required: true,
    includeIfNull: false,
  )
  final String orderId;

  @JsonKey(
    name: r'deliveryDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime deliveryDate;

  @JsonKey(
    name: r'productName',
    required: true,
    includeIfNull: false,
  )
  final String productName;

  @JsonKey(
    name: r'qty',
    required: true,
    includeIfNull: false,
  )
  final int qty;

  @JsonKey(
    name: r'amountPaise',
    required: true,
    includeIfNull: false,
  )
  final String amountPaise;

  @JsonKey(
    name: r'paymentStatus',
    required: true,
    includeIfNull: false,
  )
  final String paymentStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionDelivery &&
          other.orderId == orderId &&
          other.deliveryDate == deliveryDate &&
          other.productName == productName &&
          other.qty == qty &&
          other.amountPaise == amountPaise &&
          other.paymentStatus == paymentStatus;

  @override
  int get hashCode =>
      orderId.hashCode +
      deliveryDate.hashCode +
      productName.hashCode +
      qty.hashCode +
      amountPaise.hashCode +
      paymentStatus.hashCode;

  factory SubscriptionDelivery.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionDeliveryFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionDeliveryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
