//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'admin_dashboard.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDashboard {
  /// Returns a new [AdminDashboard] instance.
  AdminDashboard({
    required this.serverTime,
    required this.vendorsTotal,
    required this.vendorsSuspended,
    required this.kycPending,
    required this.kycVerified,
    required this.customersTotal,
    required this.customersBlocked,
    required this.ordersTotal,
    required this.ordersDelivered,
    required this.ordersFailed,
    required this.recordedGmvPaise,
    required this.gmvScope,
    required this.planAssignmentsTotal,
    required this.planRevenueStatus,
  });

  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final DateTime serverTime;

  // minimum: 0
  @JsonKey(
    name: r'vendorsTotal',
    required: true,
    includeIfNull: false,
  )
  final int vendorsTotal;

  // minimum: 0
  @JsonKey(
    name: r'vendorsSuspended',
    required: true,
    includeIfNull: false,
  )
  final int vendorsSuspended;

  // minimum: 0
  @JsonKey(
    name: r'kycPending',
    required: true,
    includeIfNull: false,
  )
  final int kycPending;

  // minimum: 0
  @JsonKey(
    name: r'kycVerified',
    required: true,
    includeIfNull: false,
  )
  final int kycVerified;

  // minimum: 0
  @JsonKey(
    name: r'customersTotal',
    required: true,
    includeIfNull: false,
  )
  final int customersTotal;

  // minimum: 0
  @JsonKey(
    name: r'customersBlocked',
    required: true,
    includeIfNull: false,
  )
  final int customersBlocked;

  // minimum: 0
  @JsonKey(
    name: r'ordersTotal',
    required: true,
    includeIfNull: false,
  )
  final int ordersTotal;

  // minimum: 0
  @JsonKey(
    name: r'ordersDelivered',
    required: true,
    includeIfNull: false,
  )
  final int ordersDelivered;

  // minimum: 0
  @JsonKey(
    name: r'ordersFailed',
    required: true,
    includeIfNull: false,
  )
  final int ordersFailed;

  /// Delivered-order component of PRD GMV only; quick-sale value unavailable until T-079/T-080. All-time stored DELIVERED order totals, including delivery charges and discounts; not cash receipts. Decimal integer paise string preserves BigInt precision.
  @JsonKey(
    name: r'recordedGmvPaise',
    required: true,
    includeIfNull: false,
  )
  final String recordedGmvPaise;

  /// Full platform GMV also requires quick-sale value, unavailable before T-079/T-080.
  @JsonKey(
    name: r'gmvScope',
    required: true,
    includeIfNull: false,
  )
  final AdminDashboardGmvScopeEnum gmvScope;

  /// All historical audited assignment rows, including superseded grants; never revenue.
  // minimum: 0
  @JsonKey(
    name: r'planAssignmentsTotal',
    required: true,
    includeIfNull: false,
  )
  final int planAssignmentsTotal;

  /// Automated plan billing is deferred; no inferred revenue.
  @JsonKey(
    name: r'planRevenueStatus',
    required: true,
    includeIfNull: false,
  )
  final AdminDashboardPlanRevenueStatusEnum planRevenueStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDashboard &&
          other.serverTime == serverTime &&
          other.vendorsTotal == vendorsTotal &&
          other.vendorsSuspended == vendorsSuspended &&
          other.kycPending == kycPending &&
          other.kycVerified == kycVerified &&
          other.customersTotal == customersTotal &&
          other.customersBlocked == customersBlocked &&
          other.ordersTotal == ordersTotal &&
          other.ordersDelivered == ordersDelivered &&
          other.ordersFailed == ordersFailed &&
          other.recordedGmvPaise == recordedGmvPaise &&
          other.gmvScope == gmvScope &&
          other.planAssignmentsTotal == planAssignmentsTotal &&
          other.planRevenueStatus == planRevenueStatus;

  @override
  int get hashCode =>
      serverTime.hashCode +
      vendorsTotal.hashCode +
      vendorsSuspended.hashCode +
      kycPending.hashCode +
      kycVerified.hashCode +
      customersTotal.hashCode +
      customersBlocked.hashCode +
      ordersTotal.hashCode +
      ordersDelivered.hashCode +
      ordersFailed.hashCode +
      recordedGmvPaise.hashCode +
      gmvScope.hashCode +
      planAssignmentsTotal.hashCode +
      planRevenueStatus.hashCode;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) =>
      _$AdminDashboardFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDashboardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Full platform GMV also requires quick-sale value, unavailable before T-079/T-080.
enum AdminDashboardGmvScopeEnum {
  @JsonValue(r'DELIVERED_ORDERS_ONLY')
  DELIVERED_ORDERS_ONLY(r'DELIVERED_ORDERS_ONLY');

  const AdminDashboardGmvScopeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

/// Automated plan billing is deferred; no inferred revenue.
enum AdminDashboardPlanRevenueStatusEnum {
  @JsonValue(r'UNAVAILABLE')
  UNAVAILABLE(r'UNAVAILABLE');

  const AdminDashboardPlanRevenueStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
