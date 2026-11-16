//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_pause.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionPause {
  /// Returns a new [SubscriptionPause] instance.
  SubscriptionPause({
    required this.version,
    this.fromDate,
    this.toDate,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  /// Defaults to earliest modifiable date; inclusive.
  @JsonKey(
    name: r'fromDate',
    required: false,
    includeIfNull: false,
  )
  final DateTime? fromDate;

  /// Inclusive; absent means open-ended.
  @JsonKey(
    name: r'toDate',
    required: false,
    includeIfNull: false,
  )
  final DateTime? toDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPause &&
          other.version == version &&
          other.fromDate == fromDate &&
          other.toDate == toDate;

  @override
  int get hashCode => version.hashCode + fromDate.hashCode + toDate.hashCode;

  factory SubscriptionPause.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPauseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPauseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
