//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'customer_subscription_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerSubscriptionInput {
  /// Returns a new [CustomerSubscriptionInput] instance.
  CustomerSubscriptionInput({
    required this.productId,
    required this.qty,
    required this.weekdays,
    required this.startDate,
    this.endDate,
    required this.timeSlot,
    required this.paymentMethod,
    required this.vendorId,
    required this.addressId,
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
  final CustomerSubscriptionInputPaymentMethodEnum paymentMethod;

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'addressId',
    required: true,
    includeIfNull: false,
  )
  final String addressId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerSubscriptionInput &&
          other.productId == productId &&
          other.qty == qty &&
          other.weekdays == weekdays &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.timeSlot == timeSlot &&
          other.paymentMethod == paymentMethod &&
          other.vendorId == vendorId &&
          other.addressId == addressId;

  @override
  int get hashCode =>
      productId.hashCode +
      qty.hashCode +
      weekdays.hashCode +
      startDate.hashCode +
      endDate.hashCode +
      timeSlot.hashCode +
      paymentMethod.hashCode +
      vendorId.hashCode +
      addressId.hashCode;

  factory CustomerSubscriptionInput.fromJson(Map<String, dynamic> json) =>
      _$CustomerSubscriptionInputFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerSubscriptionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// External payment preference; postpaid Khata, no funds held or prepaid charge.
enum CustomerSubscriptionInputPaymentMethodEnum {
  @JsonValue(r'CASH')
  CASH(r'CASH'),
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'WALLET')
  WALLET(r'WALLET');

  const CustomerSubscriptionInputPaymentMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
