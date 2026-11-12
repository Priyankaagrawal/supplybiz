//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/vendor_about_holidays_inner.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_about.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorAbout {
  /// Returns a new [VendorAbout] instance.
  VendorAbout({
    required this.id,
    required this.businessName,
    required this.categoryId,
    required this.shopPhotoMediaId,
    required this.badges,
    required this.distanceMeters,
    required this.completedOrders30Days,
    required this.favorite,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.deliveryChargePaise,
    required this.minOrderPaise,
    required this.openingHours,
    required this.holidays,
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
    includeIfNull: false,
  )
  final String businessName;

  @JsonKey(
    name: r'categoryId',
    required: true,
    includeIfNull: false,
  )
  final String categoryId;

  @JsonKey(
    name: r'shopPhotoMediaId',
    required: true,
    includeIfNull: true,
  )
  final String? shopPhotoMediaId;

  @JsonKey(
    name: r'badges',
    required: true,
    includeIfNull: false,
  )
  final List<String> badges;

  @JsonKey(
    name: r'distanceMeters',
    required: true,
    includeIfNull: false,
  )
  final num distanceMeters;

  @JsonKey(
    name: r'completedOrders30Days',
    required: true,
    includeIfNull: false,
  )
  final int completedOrders30Days;

  @JsonKey(
    name: r'favorite',
    required: true,
    includeIfNull: false,
  )
  final bool favorite;

  @JsonKey(
    name: r'address',
    required: true,
    includeIfNull: true,
  )
  final String? address;

  @JsonKey(
    name: r'city',
    required: true,
    includeIfNull: true,
  )
  final String? city;

  @JsonKey(
    name: r'state',
    required: true,
    includeIfNull: true,
  )
  final String? state;

  @JsonKey(
    name: r'pincode',
    required: true,
    includeIfNull: true,
  )
  final String? pincode;

  @JsonKey(
    name: r'deliveryChargePaise',
    required: true,
    includeIfNull: false,
  )
  final int deliveryChargePaise;

  @JsonKey(
    name: r'minOrderPaise',
    required: true,
    includeIfNull: false,
  )
  final int minOrderPaise;

  /// Unconfigured until business-hours settings exist.
  @JsonKey(
    name: r'openingHours',
    required: true,
    includeIfNull: true,
  )
  final Map<String, Object>? openingHours;

  @JsonKey(
    name: r'holidays',
    required: true,
    includeIfNull: false,
  )
  final List<VendorAboutHolidaysInner> holidays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorAbout &&
          other.id == id &&
          other.businessName == businessName &&
          other.categoryId == categoryId &&
          other.shopPhotoMediaId == shopPhotoMediaId &&
          other.badges == badges &&
          other.distanceMeters == distanceMeters &&
          other.completedOrders30Days == completedOrders30Days &&
          other.favorite == favorite &&
          other.address == address &&
          other.city == city &&
          other.state == state &&
          other.pincode == pincode &&
          other.deliveryChargePaise == deliveryChargePaise &&
          other.minOrderPaise == minOrderPaise &&
          other.openingHours == openingHours &&
          other.holidays == holidays;

  @override
  int get hashCode =>
      id.hashCode +
      businessName.hashCode +
      categoryId.hashCode +
      (shopPhotoMediaId == null ? 0 : shopPhotoMediaId.hashCode) +
      badges.hashCode +
      distanceMeters.hashCode +
      completedOrders30Days.hashCode +
      favorite.hashCode +
      (address == null ? 0 : address.hashCode) +
      (city == null ? 0 : city.hashCode) +
      (state == null ? 0 : state.hashCode) +
      (pincode == null ? 0 : pincode.hashCode) +
      deliveryChargePaise.hashCode +
      minOrderPaise.hashCode +
      (openingHours == null ? 0 : openingHours.hashCode) +
      holidays.hashCode;

  factory VendorAbout.fromJson(Map<String, dynamic> json) =>
      _$VendorAboutFromJson(json);

  Map<String, dynamic> toJson() => _$VendorAboutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
