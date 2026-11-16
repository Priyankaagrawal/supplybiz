//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_version.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionVersion {
  /// Returns a new [SubscriptionVersion] instance.
  SubscriptionVersion({
    required this.version,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionVersion && other.version == version;

  @override
  int get hashCode => version.hashCode;

  factory SubscriptionVersion.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionVersionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionVersionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
