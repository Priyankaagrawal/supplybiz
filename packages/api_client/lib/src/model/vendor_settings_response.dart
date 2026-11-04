//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_settings_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorSettingsResponse {
  /// Returns a new [VendorSettingsResponse] instance.
  VendorSettingsResponse({
    required this.serviceRadiusKm,
    required this.deliveryChargePaise,
    required this.minOrderPaise,
    required this.timeSlots,
    required this.autoAcceptSubscriptions,
    required this.acceptingToday,
    required this.deliveryPaused,
    required this.allowKhataOrders,
    required this.version,
  });

  @JsonKey(
    name: r'serviceRadiusKm',
    required: true,
    includeIfNull: true,
  )
  final int? serviceRadiusKm;

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

  @JsonKey(
    name: r'timeSlots',
    required: true,
    includeIfNull: false,
  )
  final List<String> timeSlots;

  @JsonKey(
    name: r'autoAcceptSubscriptions',
    required: true,
    includeIfNull: false,
  )
  final bool autoAcceptSubscriptions;

  @JsonKey(
    name: r'acceptingToday',
    required: true,
    includeIfNull: false,
  )
  final bool acceptingToday;

  @JsonKey(
    name: r'deliveryPaused',
    required: true,
    includeIfNull: false,
  )
  final bool deliveryPaused;

  @JsonKey(
    name: r'allowKhataOrders',
    required: true,
    includeIfNull: false,
  )
  final bool allowKhataOrders;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorSettingsResponse &&
          other.serviceRadiusKm == serviceRadiusKm &&
          other.deliveryChargePaise == deliveryChargePaise &&
          other.minOrderPaise == minOrderPaise &&
          other.timeSlots == timeSlots &&
          other.autoAcceptSubscriptions == autoAcceptSubscriptions &&
          other.acceptingToday == acceptingToday &&
          other.deliveryPaused == deliveryPaused &&
          other.allowKhataOrders == allowKhataOrders &&
          other.version == version;

  @override
  int get hashCode =>
      (serviceRadiusKm == null ? 0 : serviceRadiusKm.hashCode) +
      deliveryChargePaise.hashCode +
      minOrderPaise.hashCode +
      timeSlots.hashCode +
      autoAcceptSubscriptions.hashCode +
      acceptingToday.hashCode +
      deliveryPaused.hashCode +
      allowKhataOrders.hashCode +
      version.hashCode;

  factory VendorSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$VendorSettingsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VendorSettingsResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
