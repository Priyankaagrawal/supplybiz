//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_patch.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionPatch {
  /// Returns a new [SubscriptionPatch] instance.
  SubscriptionPatch({
    required this.version,
    this.qty,
    this.weekdays,
    this.timeSlot,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'qty',
    required: false,
    includeIfNull: false,
  )
  final int? qty;

  @JsonKey(
    name: r'weekdays',
    required: false,
    includeIfNull: false,
  )
  final List<num>? weekdays;

  @JsonKey(
    name: r'timeSlot',
    required: false,
    includeIfNull: false,
  )
  final String? timeSlot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPatch &&
          other.version == version &&
          other.qty == qty &&
          other.weekdays == weekdays &&
          other.timeSlot == timeSlot;

  @override
  int get hashCode =>
      version.hashCode + qty.hashCode + weekdays.hashCode + timeSlot.hashCode;

  factory SubscriptionPatch.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPatchFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
