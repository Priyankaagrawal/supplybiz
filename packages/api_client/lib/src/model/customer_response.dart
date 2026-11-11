//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'customer_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerResponse {
  /// Returns a new [CustomerResponse] instance.
  CustomerResponse({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.address,
    required this.preferredPayment,
    required this.status,
    required this.linkStatus,
    required this.userId,
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
    name: r'email',
    required: true,
    includeIfNull: true,
  )
  final String? email;

  @JsonKey(
    name: r'address',
    required: true,
    includeIfNull: false,
  )
  final String address;

  @JsonKey(
    name: r'preferredPayment',
    required: true,
    includeIfNull: false,
  )
  final CustomerResponsePreferredPaymentEnum preferredPayment;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final CustomerResponseStatusEnum status;

  @JsonKey(
    name: r'linkStatus',
    required: true,
    includeIfNull: false,
  )
  final CustomerResponseLinkStatusEnum linkStatus;

  @JsonKey(
    name: r'userId',
    required: true,
    includeIfNull: true,
  )
  final String? userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerResponse &&
          other.id == id &&
          other.name == name &&
          other.mobile == mobile &&
          other.email == email &&
          other.address == address &&
          other.preferredPayment == preferredPayment &&
          other.status == status &&
          other.linkStatus == linkStatus &&
          other.userId == userId;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      mobile.hashCode +
      (email == null ? 0 : email.hashCode) +
      address.hashCode +
      preferredPayment.hashCode +
      status.hashCode +
      linkStatus.hashCode +
      (userId == null ? 0 : userId.hashCode);

  factory CustomerResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CustomerResponsePreferredPaymentEnum {
  @JsonValue(r'CASH')
  CASH(r'CASH'),
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'BANK')
  BANK(r'BANK'),
  @JsonValue(r'WALLET')
  WALLET(r'WALLET');

  const CustomerResponsePreferredPaymentEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CustomerResponseStatusEnum {
  @JsonValue(r'ACTIVE')
  ACTIVE(r'ACTIVE'),
  @JsonValue(r'INACTIVE')
  INACTIVE(r'INACTIVE');

  const CustomerResponseStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CustomerResponseLinkStatusEnum {
  @JsonValue(r'UNLINKED')
  UNLINKED(r'UNLINKED'),
  @JsonValue(r'LINKED')
  LINKED(r'LINKED');

  const CustomerResponseLinkStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
