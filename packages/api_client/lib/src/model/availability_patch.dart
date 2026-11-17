//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'availability_patch.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AvailabilityPatch {
  /// Returns a new [AvailabilityPatch] instance.
  AvailabilityPatch({
    required this.version,
    this.acceptingToday,
    this.deliveryPaused,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  /// False rejects new one-time orders for today; existing orders remain.
  @JsonKey(
    name: r'acceptingToday',
    required: false,
    includeIfNull: false,
  )
  final bool? acceptingToday;

  /// Open-ended delivery pause. True cancels NEW/ACCEPTED/PREPARING orders today onward; progressed orders remain.
  @JsonKey(
    name: r'deliveryPaused',
    required: false,
    includeIfNull: false,
  )
  final bool? deliveryPaused;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityPatch &&
          other.version == version &&
          other.acceptingToday == acceptingToday &&
          other.deliveryPaused == deliveryPaused;

  @override
  int get hashCode =>
      version.hashCode + acceptingToday.hashCode + deliveryPaused.hashCode;

  factory AvailabilityPatch.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityPatchFromJson(json);

  Map<String, dynamic> toJson() => _$AvailabilityPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
