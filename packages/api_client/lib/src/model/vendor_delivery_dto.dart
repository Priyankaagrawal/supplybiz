//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_delivery_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorDeliveryDto {
  /// Returns a new [VendorDeliveryDto] instance.
  VendorDeliveryDto({
    required this.version,
    required this.deliveryChargePaise,
    required this.minOrderPaise,
    required this.timeSlots,
    required this.acceptingToday,
    required this.sameDayCutoff,
  });

  // minimum: 1
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  // minimum: 0
  // maximum: 2147483647
  @JsonKey(
    name: r'deliveryChargePaise',
    required: true,
    includeIfNull: false,
  )
  final int deliveryChargePaise;

  // minimum: 0
  // maximum: 2147483647
  @JsonKey(
    name: r'minOrderPaise',
    required: true,
    includeIfNull: false,
  )
  final int minOrderPaise;

  /// Explicit IST HH:mm-HH:mm slots; no overnight/overlapping slots. Empty disables checkout slots.
  @JsonKey(
    name: r'timeSlots',
    required: true,
    includeIfNull: false,
  )
  final List<String> timeSlots;

  @JsonKey(
    name: r'acceptingToday',
    required: true,
    includeIfNull: false,
  )
  final bool acceptingToday;

  /// IST HH:mm; required when acceptingToday is true.
  @JsonKey(
    name: r'sameDayCutoff',
    required: true,
    includeIfNull: true,
  )
  final String? sameDayCutoff;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorDeliveryDto &&
          other.version == version &&
          other.deliveryChargePaise == deliveryChargePaise &&
          other.minOrderPaise == minOrderPaise &&
          other.timeSlots == timeSlots &&
          other.acceptingToday == acceptingToday &&
          other.sameDayCutoff == sameDayCutoff;

  @override
  int get hashCode =>
      version.hashCode +
      deliveryChargePaise.hashCode +
      minOrderPaise.hashCode +
      timeSlots.hashCode +
      acceptingToday.hashCode +
      (sameDayCutoff == null ? 0 : sameDayCutoff.hashCode);

  factory VendorDeliveryDto.fromJson(Map<String, dynamic> json) =>
      _$VendorDeliveryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VendorDeliveryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
