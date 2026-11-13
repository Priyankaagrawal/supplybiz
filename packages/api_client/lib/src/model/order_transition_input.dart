//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/delivery_payment_input.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_transition_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderTransitionInput {
  /// Returns a new [OrderTransitionInput] instance.
  OrderTransitionInput({
    required this.to,
    required this.version,
    this.reason,
    this.reasonText,
    this.payment,
  });

  @JsonKey(
    name: r'to',
    required: true,
    includeIfNull: false,
  )
  final OrderTransitionInputToEnum to;

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  /// REJECTED: CUSTOMER_UNAVAILABLE/OUT_OF_STOCK/NOT_SERVICEABLE/CUSTOMER_REQUEST/OTHER. FAILED: required nonempty free text, up to 200 characters.
  @JsonKey(
    name: r'reason',
    required: false,
    includeIfNull: false,
  )
  final String? reason;

  /// Required for OTHER; 5–200 characters.
  @JsonKey(
    name: r'reasonText',
    required: false,
    includeIfNull: false,
  )
  final String? reasonText;

  /// Required for DELIVERED; collected=false forbids method/amount.
  @JsonKey(
    name: r'payment',
    required: false,
    includeIfNull: false,
  )
  final DeliveryPaymentInput? payment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderTransitionInput &&
          other.to == to &&
          other.version == version &&
          other.reason == reason &&
          other.reasonText == reasonText &&
          other.payment == payment;

  @override
  int get hashCode =>
      to.hashCode +
      version.hashCode +
      reason.hashCode +
      reasonText.hashCode +
      payment.hashCode;

  factory OrderTransitionInput.fromJson(Map<String, dynamic> json) =>
      _$OrderTransitionInputFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTransitionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum OrderTransitionInputToEnum {
  @JsonValue(r'ACCEPTED')
  ACCEPTED(r'ACCEPTED'),
  @JsonValue(r'REJECTED')
  REJECTED(r'REJECTED'),
  @JsonValue(r'PREPARING')
  PREPARING(r'PREPARING'),
  @JsonValue(r'OUT_FOR_DELIVERY')
  OUT_FOR_DELIVERY(r'OUT_FOR_DELIVERY'),
  @JsonValue(r'DELIVERED')
  DELIVERED(r'DELIVERED'),
  @JsonValue(r'FAILED')
  FAILED(r'FAILED');

  const OrderTransitionInputToEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
