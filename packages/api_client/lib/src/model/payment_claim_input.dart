//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'payment_claim_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentClaimInput {
  /// Returns a new [PaymentClaimInput] instance.
  PaymentClaimInput({
    required this.vendorCustomerId,
    required this.amountPaise,
    required this.method,
    this.upiTxnRef,
  });

  /// Select an accepted owned billing account returned by vendor entries; no mobile matching or silent allocation.
  @JsonKey(
    name: r'vendorCustomerId',
    required: true,
    includeIfNull: false,
  )
  final String vendorCustomerId;

  @JsonKey(
    name: r'amountPaise',
    required: true,
    includeIfNull: false,
  )
  final String amountPaise;

  /// Customer statement of external payment, not provider verification.
  @JsonKey(
    name: r'method',
    required: true,
    includeIfNull: false,
  )
  final PaymentClaimInputMethodEnum method;

  /// Unverified customer-supplied transaction reference.
  @JsonKey(
    name: r'upiTxnRef',
    required: false,
    includeIfNull: false,
  )
  final String? upiTxnRef;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentClaimInput &&
          other.vendorCustomerId == vendorCustomerId &&
          other.amountPaise == amountPaise &&
          other.method == method &&
          other.upiTxnRef == upiTxnRef;

  @override
  int get hashCode =>
      vendorCustomerId.hashCode +
      amountPaise.hashCode +
      method.hashCode +
      upiTxnRef.hashCode;

  factory PaymentClaimInput.fromJson(Map<String, dynamic> json) =>
      _$PaymentClaimInputFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentClaimInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Customer statement of external payment, not provider verification.
enum PaymentClaimInputMethodEnum {
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'CASH')
  CASH(r'CASH');

  const PaymentClaimInputMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
