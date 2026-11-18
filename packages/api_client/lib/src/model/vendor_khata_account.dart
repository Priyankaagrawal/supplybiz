//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_khata_account.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorKhataAccount {
  /// Returns a new [VendorKhataAccount] instance.
  VendorKhataAccount({
    required this.id,
    required this.name,
    required this.mobile,
    required this.status,
    required this.archived,
    required this.totalDebitPaise,
    required this.totalCreditPaise,
    required this.totalPaidPaise,
    required this.duePaise,
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
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'archived',
    required: true,
    includeIfNull: false,
  )
  final bool archived;

  @JsonKey(
    name: r'totalDebitPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalDebitPaise;

  @JsonKey(
    name: r'totalCreditPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalCreditPaise;

  @JsonKey(
    name: r'totalPaidPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalPaidPaise;

  @JsonKey(
    name: r'duePaise',
    required: true,
    includeIfNull: false,
  )
  final String duePaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorKhataAccount &&
          other.id == id &&
          other.name == name &&
          other.mobile == mobile &&
          other.status == status &&
          other.archived == archived &&
          other.totalDebitPaise == totalDebitPaise &&
          other.totalCreditPaise == totalCreditPaise &&
          other.totalPaidPaise == totalPaidPaise &&
          other.duePaise == duePaise;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      mobile.hashCode +
      status.hashCode +
      archived.hashCode +
      totalDebitPaise.hashCode +
      totalCreditPaise.hashCode +
      totalPaidPaise.hashCode +
      duePaise.hashCode;

  factory VendorKhataAccount.fromJson(Map<String, dynamic> json) =>
      _$VendorKhataAccountFromJson(json);

  Map<String, dynamic> toJson() => _$VendorKhataAccountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
