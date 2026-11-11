//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/managed_customer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'managed_vendor_detail.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedVendorDetail {
  /// Returns a new [ManagedVendorDetail] instance.
  ManagedVendorDetail({
    required this.id,
    required this.businessName,
    required this.account,
    required this.category,
    required this.city,
    required this.kycStatus,
    required this.isSuspended,
    required this.badges,
    required this.updatedAt,
    required this.planCode,
    required this.planStatus,
    required this.planStartsAt,
    required this.planEndsAt,
    required this.customerLimit,
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

  @JsonKey(
    name: r'planCode',
    required: true,
    includeIfNull: true,
  )
  final String? planCode;

  @JsonKey(
    name: r'planStatus',
    required: true,
    includeIfNull: false,
  )
  final ManagedVendorDetailPlanStatusEnum planStatus;

  @JsonKey(
    name: r'planStartsAt',
    required: true,
    includeIfNull: true,
  )
  final DateTime? planStartsAt;

  @JsonKey(
    name: r'planEndsAt',
    required: true,
    includeIfNull: true,
  )
  final DateTime? planEndsAt;

  @JsonKey(
    name: r'customerLimit',
    required: true,
    includeIfNull: false,
  )
  final int customerLimit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedVendorDetail &&
          other.id == id &&
          other.businessName == businessName &&
          other.account == account &&
          other.category == category &&
          other.city == city &&
          other.kycStatus == kycStatus &&
          other.isSuspended == isSuspended &&
          other.badges == badges &&
          other.updatedAt == updatedAt &&
          other.planCode == planCode &&
          other.planStatus == planStatus &&
          other.planStartsAt == planStartsAt &&
          other.planEndsAt == planEndsAt &&
          other.customerLimit == customerLimit;

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
      updatedAt.hashCode +
      (planCode == null ? 0 : planCode.hashCode) +
      planStatus.hashCode +
      (planStartsAt == null ? 0 : planStartsAt.hashCode) +
      (planEndsAt == null ? 0 : planEndsAt.hashCode) +
      customerLimit.hashCode;

  factory ManagedVendorDetail.fromJson(Map<String, dynamic> json) =>
      _$ManagedVendorDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedVendorDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ManagedVendorDetailPlanStatusEnum {
  @JsonValue(r'UNASSIGNED')
  UNASSIGNED(r'UNASSIGNED'),
  @JsonValue(r'ACTIVE')
  ACTIVE(r'ACTIVE'),
  @JsonValue(r'EXPIRED')
  EXPIRED(r'EXPIRED'),
  @JsonValue(r'SCHEDULED')
  SCHEDULED(r'SCHEDULED'),
  @JsonValue(r'UNAVAILABLE')
  UNAVAILABLE(r'UNAVAILABLE');

  const ManagedVendorDetailPlanStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
