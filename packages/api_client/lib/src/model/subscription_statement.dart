//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/khata_vendor_entries.dart';
import 'package:supplybiz_api_client/src/model/subscription_delivery.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_statement.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionStatement {
  /// Returns a new [SubscriptionStatement] instance.
  SubscriptionStatement({
    required this.subscriptionId,
    required this.month,
    required this.items,
    required this.total,
    required this.deliveredAmountPaise,
    required this.deliveredQty,
    required this.ledger,
  });

  @JsonKey(
    name: r'subscriptionId',
    required: true,
    includeIfNull: false,
  )
  final String subscriptionId;

  @JsonKey(
    name: r'month',
    required: true,
    includeIfNull: false,
  )
  final String month;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<SubscriptionDelivery> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  /// Full selected-month delivered subtotal, independent of pagination.
  @JsonKey(
    name: r'deliveredAmountPaise',
    required: true,
    includeIfNull: false,
  )
  final String deliveredAmountPaise;

  /// Full selected-month delivered pack quantity, exact decimal string.
  @JsonKey(
    name: r'deliveredQty',
    required: true,
    includeIfNull: false,
  )
  final String deliveredQty;

  /// Shared vendor account ledger. Unallocated payments/claims are not assigned to individual subscriptions.
  @JsonKey(
    name: r'ledger',
    required: true,
    includeIfNull: false,
  )
  final KhataVendorEntries ledger;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionStatement &&
          other.subscriptionId == subscriptionId &&
          other.month == month &&
          other.items == items &&
          other.total == total &&
          other.deliveredAmountPaise == deliveredAmountPaise &&
          other.deliveredQty == deliveredQty &&
          other.ledger == ledger;

  @override
  int get hashCode =>
      subscriptionId.hashCode +
      month.hashCode +
      items.hashCode +
      total.hashCode +
      deliveredAmountPaise.hashCode +
      deliveredQty.hashCode +
      ledger.hashCode;

  factory SubscriptionStatement.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatementFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionStatementToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
