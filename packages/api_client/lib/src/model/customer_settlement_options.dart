//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/khata_billing_account.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_settlement_options.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerSettlementOptions {
  /// Returns a new [CustomerSettlementOptions] instance.
  CustomerSettlementOptions({
    required this.vendorId,
    required this.payeeName,
    required this.upiId,
    required this.upiAvailable,
    required this.cashAvailable,
    required this.duePaise,
    required this.accounts,
  });

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'payeeName',
    required: true,
    includeIfNull: false,
  )
  final String payeeName;

  /// Only an explicitly published payment setting; never verification-only KYC.
  @JsonKey(
    name: r'upiId',
    required: true,
    includeIfNull: true,
  )
  final String? upiId;

  @JsonKey(
    name: r'upiAvailable',
    required: true,
    includeIfNull: false,
  )
  final bool upiAvailable;

  @JsonKey(
    name: r'cashAvailable',
    required: true,
    includeIfNull: false,
  )
  final bool cashAvailable;

  @JsonKey(
    name: r'duePaise',
    required: true,
    includeIfNull: false,
  )
  final String duePaise;

  @JsonKey(
    name: r'accounts',
    required: true,
    includeIfNull: false,
  )
  final List<KhataBillingAccount> accounts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerSettlementOptions &&
          other.vendorId == vendorId &&
          other.payeeName == payeeName &&
          other.upiId == upiId &&
          other.upiAvailable == upiAvailable &&
          other.cashAvailable == cashAvailable &&
          other.duePaise == duePaise &&
          other.accounts == accounts;

  @override
  int get hashCode =>
      vendorId.hashCode +
      payeeName.hashCode +
      (upiId == null ? 0 : upiId.hashCode) +
      upiAvailable.hashCode +
      cashAvailable.hashCode +
      duePaise.hashCode +
      accounts.hashCode;

  factory CustomerSettlementOptions.fromJson(Map<String, dynamic> json) =>
      _$CustomerSettlementOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerSettlementOptionsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
