//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'discovered_vendor.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DiscoveredVendor {
  /// Returns a new [DiscoveredVendor] instance.
  DiscoveredVendor({
    required this.id,
    required this.businessName,
    required this.categoryId,
    required this.shopPhotoMediaId,
    required this.badges,
    required this.distanceMeters,
    required this.completedOrders30Days,
    required this.favorite,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredVendor &&
          other.id == id &&
          other.businessName == businessName &&
          other.categoryId == categoryId &&
          other.shopPhotoMediaId == shopPhotoMediaId &&
          other.badges == badges &&
          other.distanceMeters == distanceMeters &&
          other.completedOrders30Days == completedOrders30Days &&
          other.favorite == favorite;

  @override
  int get hashCode =>
      id.hashCode +
      businessName.hashCode +
      categoryId.hashCode +
      (shopPhotoMediaId == null ? 0 : shopPhotoMediaId.hashCode) +
      badges.hashCode +
      distanceMeters.hashCode +
      completedOrders30Days.hashCode +
      favorite.hashCode;

  factory DiscoveredVendor.fromJson(Map<String, dynamic> json) =>
      _$DiscoveredVendorFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoveredVendorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
