//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'khata_billing_account.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KhataBillingAccount {
  /// Returns a new [KhataBillingAccount] instance.
  KhataBillingAccount({
    required this.vendorCustomerId,
    required this.duePaise,
    required this.maxClaimPaise,
    required this.canClaim,
  });

  @JsonKey(
    name: r'vendorCustomerId',
    required: true,
    includeIfNull: false,
  )
  final String vendorCustomerId;

  @JsonKey(
    name: r'duePaise',
    required: true,
    includeIfNull: false,
  )
  final String duePaise;

  @JsonKey(
    name: r'maxClaimPaise',
    required: true,
    includeIfNull: false,
  )
  final String maxClaimPaise;

  @JsonKey(
    name: r'canClaim',
    required: true,
    includeIfNull: false,
  )
  final bool canClaim;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhataBillingAccount &&
          other.vendorCustomerId == vendorCustomerId &&
          other.duePaise == duePaise &&
          other.maxClaimPaise == maxClaimPaise &&
          other.canClaim == canClaim;

  @override
  int get hashCode =>
      vendorCustomerId.hashCode +
      duePaise.hashCode +
      maxClaimPaise.hashCode +
      canClaim.hashCode;

  factory KhataBillingAccount.fromJson(Map<String, dynamic> json) =>
      _$KhataBillingAccountFromJson(json);

  Map<String, dynamic> toJson() => _$KhataBillingAccountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
