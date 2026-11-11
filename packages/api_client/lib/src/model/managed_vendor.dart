//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/managed_customer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'managed_vendor.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedVendor {
  /// Returns a new [ManagedVendor] instance.
  ManagedVendor({
    required this.id,
    required this.businessName,
    required this.account,
    required this.category,
    required this.city,
    required this.kycStatus,
    required this.isSuspended,
    required this.badges,
    required this.updatedAt,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'businessName',
    required: true,
    includeIfNull: true,
  )
  final String? businessName;

  @JsonKey(
    name: r'account',
    required: true,
    includeIfNull: false,
  )
  final ManagedCustomer account;

  @JsonKey(
    name: r'category',
    required: true,
    includeIfNull: false,
  )
  final String category;

  @JsonKey(
    name: r'city',
    required: true,
    includeIfNull: true,
  )
  final String? city;

  @JsonKey(
    name: r'kycStatus',
    required: true,
    includeIfNull: false,
  )
  final String kycStatus;

  @JsonKey(
    name: r'isSuspended',
    required: true,
    includeIfNull: false,
  )
  final bool isSuspended;

  @JsonKey(
    name: r'badges',
    required: true,
    includeIfNull: false,
  )
  final List<String> badges;

  @JsonKey(
    name: r'updatedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedVendor &&
          other.id == id &&
          other.businessName == businessName &&
          other.account == account &&
          other.category == category &&
          other.city == city &&
          other.kycStatus == kycStatus &&
          other.isSuspended == isSuspended &&
          other.badges == badges &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      id.hashCode +
      (businessName == null ? 0 : businessName.hashCode) +
      account.hashCode +
      category.hashCode +
      (city == null ? 0 : city.hashCode) +
      kycStatus.hashCode +
      isSuspended.hashCode +
      badges.hashCode +
      updatedAt.hashCode;

  factory ManagedVendor.fromJson(Map<String, dynamic> json) =>
      _$ManagedVendorFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedVendorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
