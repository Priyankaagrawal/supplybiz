//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/customer_input.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_subscription_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorSubscriptionInput {
  /// Returns a new [VendorSubscriptionInput] instance.
  VendorSubscriptionInput({
    required this.productId,
    required this.qty,
    required this.weekdays,
    required this.startDate,
    this.endDate,
    required this.timeSlot,
    required this.paymentMethod,
    this.vendorCustomerId,
    this.newCustomer,
  });

  @JsonKey(
    name: r'productId',
    required: true,
    includeIfNull: false,
  )
  final String productId;

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'qty',
    required: true,
    includeIfNull: false,
  )
  final int qty;

  /// ISO weekdays 1=Monday through 7=Sunday, unique.
  @JsonKey(
    name: r'weekdays',
    required: true,
    includeIfNull: false,
  )
  final List<num> weekdays;

  @JsonKey(
    name: r'startDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime startDate;

  @JsonKey(
    name: r'endDate',
    required: false,
    includeIfNull: false,
  )
  final DateTime? endDate;

  @JsonKey(
    name: r'timeSlot',
    required: true,
    includeIfNull: false,
  )
  final String timeSlot;

  /// External payment preference; postpaid Khata, no funds held or prepaid charge.
  @JsonKey(
    name: r'paymentMethod',
    required: true,
    includeIfNull: false,
  )
  final VendorSubscriptionInputPaymentMethodEnum paymentMethod;

  @JsonKey(
    name: r'vendorCustomerId',
    required: false,
    includeIfNull: false,
  )
  final String? vendorCustomerId;

  /// Exactly one of vendorCustomerId or newCustomer.
  @JsonKey(
    name: r'newCustomer',
    required: false,
    includeIfNull: false,
  )
  final CustomerInput? newCustomer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorSubscriptionInput &&
          other.productId == productId &&
          other.qty == qty &&
          other.weekdays == weekdays &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.timeSlot == timeSlot &&
          other.paymentMethod == paymentMethod &&
          other.vendorCustomerId == vendorCustomerId &&
          other.newCustomer == newCustomer;

  @override
  int get hashCode =>
      productId.hashCode +
      qty.hashCode +
      weekdays.hashCode +
      startDate.hashCode +
      endDate.hashCode +
      timeSlot.hashCode +
      paymentMethod.hashCode +
      vendorCustomerId.hashCode +
      newCustomer.hashCode;

  factory VendorSubscriptionInput.fromJson(Map<String, dynamic> json) =>
      _$VendorSubscriptionInputFromJson(json);

  Map<String, dynamic> toJson() => _$VendorSubscriptionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// External payment preference; postpaid Khata, no funds held or prepaid charge.
enum VendorSubscriptionInputPaymentMethodEnum {
  @JsonValue(r'CASH')
  CASH(r'CASH'),
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'WALLET')
  WALLET(r'WALLET');

  const VendorSubscriptionInputPaymentMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
