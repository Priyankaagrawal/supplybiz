//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_dashboard.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorDashboard {
  /// Returns a new [VendorDashboard] instance.
  VendorDashboard({
    required this.serverTime,
    required this.businessDate,
    required this.date,
    required this.shopName,
    required this.city,
    required this.shopPhotoMediaId,
    required this.verified,
    required this.todayOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.todaySalesPaise,
    required this.totalEarningsPaise,
    required this.milkStockLitres,
    required this.milkStockUnmeasuredProducts,
    required this.activeCustomers,
  });

  /// Database snapshot time for last-updated display.
  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final DateTime serverTime;

  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  /// Selected IST date. Order counts use scheduled delivery date; sales use actual completion/sale date.
  @JsonKey(
    name: r'date',
    required: true,
    includeIfNull: false,
  )
  final DateTime date;

  @JsonKey(
    name: r'shopName',
    required: true,
    includeIfNull: true,
  )
  final String? shopName;

  @JsonKey(
    name: r'city',
    required: true,
    includeIfNull: true,
  )
  final String? city;

  /// Owned photo ID for the existing authorized media route.
  @JsonKey(
    name: r'shopPhotoMediaId',
    required: true,
    includeIfNull: true,
  )
  final String? shopPhotoMediaId;

  /// Stored VERIFIED KYC only; no provider verification implied.
  @JsonKey(
    name: r'verified',
    required: true,
    includeIfNull: false,
  )
  final bool verified;

  /// All retained orders scheduled for selected date, including cancelled/rejected/failed.
  // minimum: 0
  @JsonKey(
    name: r'todayOrders',
    required: true,
    includeIfNull: false,
  )
  final int todayOrders;

  /// NEW, ACCEPTED, PREPARING or OUT_FOR_DELIVERY on selected delivery date.
  // minimum: 0
  @JsonKey(
    name: r'pendingOrders',
    required: true,
    includeIfNull: false,
  )
  final int pendingOrders;

  /// DELIVERED on selected delivery date.
  // minimum: 0
  @JsonKey(
    name: r'completedOrders',
    required: true,
    includeIfNull: false,
  )
  final int completedOrders;

  /// Selected IST completion/sale date gross: delivered order totals plus POS totals. Stored discounts/delivery charges included; not receipts, ledger credits or plan revenue.
  @JsonKey(
    name: r'todaySalesPaise',
    required: true,
    includeIfNull: false,
  )
  final String todaySalesPaise;

  /// Lifetime DELIVERED order totals plus POS totals. Recorded sales, not profit or money received; independent payments/claims/reversals are not new sales.
  @JsonKey(
    name: r'totalEarningsPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalEarningsPaise;

  /// Current known milk litres: active non-deleted MILK stock times pack volume, L plus ML/1000. Exact decimal, independent of date.
  @JsonKey(
    name: r'milkStockLitres',
    required: true,
    includeIfNull: false,
  )
  final String milkStockLitres;

  /// Active stocked milk products in G/KG/PCS excluded from litres because volume is unknown. Disclose incomplete volume when nonzero.
  // minimum: 0
  @JsonKey(
    name: r'milkStockUnmeasuredProducts',
    required: true,
    includeIfNull: false,
  )
  final int milkStockUnmeasuredProducts;

  /// Current ACTIVE non-deleted vendor customer links including offline customers; independent of date.
  // minimum: 0
  @JsonKey(
    name: r'activeCustomers',
    required: true,
    includeIfNull: false,
  )
  final int activeCustomers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorDashboard &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.date == date &&
          other.shopName == shopName &&
          other.city == city &&
          other.shopPhotoMediaId == shopPhotoMediaId &&
          other.verified == verified &&
          other.todayOrders == todayOrders &&
          other.pendingOrders == pendingOrders &&
          other.completedOrders == completedOrders &&
          other.todaySalesPaise == todaySalesPaise &&
          other.totalEarningsPaise == totalEarningsPaise &&
          other.milkStockLitres == milkStockLitres &&
          other.milkStockUnmeasuredProducts == milkStockUnmeasuredProducts &&
          other.activeCustomers == activeCustomers;

  @override
  int get hashCode =>
      serverTime.hashCode +
      businessDate.hashCode +
      date.hashCode +
      (shopName == null ? 0 : shopName.hashCode) +
      (city == null ? 0 : city.hashCode) +
      (shopPhotoMediaId == null ? 0 : shopPhotoMediaId.hashCode) +
      verified.hashCode +
      todayOrders.hashCode +
      pendingOrders.hashCode +
      completedOrders.hashCode +
      todaySalesPaise.hashCode +
      totalEarningsPaise.hashCode +
      milkStockLitres.hashCode +
      milkStockUnmeasuredProducts.hashCode +
      activeCustomers.hashCode;

  factory VendorDashboard.fromJson(Map<String, dynamic> json) =>
      _$VendorDashboardFromJson(json);

  Map<String, dynamic> toJson() => _$VendorDashboardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
