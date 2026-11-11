//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'customer_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerInput {
  /// Returns a new [CustomerInput] instance.
  CustomerInput({
    required this.name,
    required this.mobile,
    this.email,
    this.address,
    this.preferredPayment,
  });

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  /// Indian mobile, ten digits or +91-prefixed. Stored in +91 form.
  @JsonKey(
    name: r'mobile',
    required: true,
    includeIfNull: false,
  )
  final String mobile;

  @JsonKey(
    name: r'email',
    required: false,
    includeIfNull: false,
  )
  final String? email;

  /// Defaults to empty on creation; omission preserves the address on PATCH.
  @JsonKey(
    name: r'address',
    required: false,
    includeIfNull: false,
  )
  final String? address;

  /// Defaults to CASH on creation; omission preserves the method on PATCH.
  @JsonKey(
    name: r'preferredPayment',
    required: false,
    includeIfNull: false,
  )
  final CustomerInputPreferredPaymentEnum? preferredPayment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerInput &&
          other.name == name &&
          other.mobile == mobile &&
          other.email == email &&
          other.address == address &&
          other.preferredPayment == preferredPayment;

  @override
  int get hashCode =>
      name.hashCode +
      mobile.hashCode +
      (email == null ? 0 : email.hashCode) +
      address.hashCode +
      preferredPayment.hashCode;

  factory CustomerInput.fromJson(Map<String, dynamic> json) =>
      _$CustomerInputFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Defaults to CASH on creation; omission preserves the method on PATCH.
enum CustomerInputPreferredPaymentEnum {
  @JsonValue(r'CASH')
  CASH(r'CASH'),
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'BANK')
  BANK(r'BANK'),
  @JsonValue(r'WALLET')
  WALLET(r'WALLET');

  const CustomerInputPreferredPaymentEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
