//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'customer_patch.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerPatch {
  /// Returns a new [CustomerPatch] instance.
  CustomerPatch({
    this.name,
    this.mobile,
    this.email,
    this.address,
    this.preferredPayment,
    this.status,
  });

  @JsonKey(
    name: r'name',
    required: false,
    includeIfNull: false,
  )
  final String? name;

  /// Indian mobile, ten digits or +91-prefixed. Stored in +91 form.
  @JsonKey(
    name: r'mobile',
    required: false,
    includeIfNull: false,
  )
  final String? mobile;

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
  final CustomerPatchPreferredPaymentEnum? preferredPayment;

  @JsonKey(
    name: r'status',
    required: false,
    includeIfNull: false,
  )
  final CustomerPatchStatusEnum? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerPatch &&
          other.name == name &&
          other.mobile == mobile &&
          other.email == email &&
          other.address == address &&
          other.preferredPayment == preferredPayment &&
          other.status == status;

  @override
  int get hashCode =>
      name.hashCode +
      mobile.hashCode +
      (email == null ? 0 : email.hashCode) +
      address.hashCode +
      preferredPayment.hashCode +
      status.hashCode;

  factory CustomerPatch.fromJson(Map<String, dynamic> json) =>
      _$CustomerPatchFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Defaults to CASH on creation; omission preserves the method on PATCH.
enum CustomerPatchPreferredPaymentEnum {
  @JsonValue(r'CASH')
  CASH(r'CASH'),
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'BANK')
  BANK(r'BANK'),
  @JsonValue(r'WALLET')
  WALLET(r'WALLET');

  const CustomerPatchPreferredPaymentEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CustomerPatchStatusEnum {
  @JsonValue(r'ACTIVE')
  ACTIVE(r'ACTIVE'),
  @JsonValue(r'INACTIVE')
  INACTIVE(r'INACTIVE');

  const CustomerPatchStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
