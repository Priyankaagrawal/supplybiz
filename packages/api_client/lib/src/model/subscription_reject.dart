//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_reject.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionReject {
  /// Returns a new [SubscriptionReject] instance.
  SubscriptionReject({
    required this.version,
    this.reason,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'reason',
    required: false,
    includeIfNull: false,
  )
  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionReject &&
          other.version == version &&
          other.reason == reason;

  @override
  int get hashCode => version.hashCode + reason.hashCode;

  factory SubscriptionReject.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionRejectFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionRejectToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
