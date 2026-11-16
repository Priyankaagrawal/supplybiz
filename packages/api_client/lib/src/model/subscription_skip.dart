//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_skip.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionSkip {
  /// Returns a new [SubscriptionSkip] instance.
  SubscriptionSkip({
    required this.version,
    required this.date,
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
    name: r'date',
    required: true,
    includeIfNull: false,
  )
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSkip &&
          other.version == version &&
          other.date == date;

  @override
  int get hashCode => version.hashCode + date.hashCode;

  factory SubscriptionSkip.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSkipFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionSkipToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
