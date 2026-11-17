//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'availability_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AvailabilityResponse {
  /// Returns a new [AvailabilityResponse] instance.
  AvailabilityResponse({
    required this.version,
    required this.acceptingToday,
    required this.deliveryPaused,
    required this.deliveryPausedUntil,
    required this.canResume,
    required this.canReduceActivity,
    required this.serverTime,
    required this.businessDate,
  });

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

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

  /// Legacy finite pause end; PATCH deliveryPaused always clears it to implement open-ended pause/resume.
  @JsonKey(
    name: r'deliveryPausedUntil',
    required: true,
    includeIfNull: true,
  )
  final DateTime? deliveryPausedUntil;

  @JsonKey(
    name: r'canResume',
    required: true,
    includeIfNull: false,
  )
  final bool canResume;

  @JsonKey(
    name: r'canReduceActivity',
    required: true,
    includeIfNull: false,
  )
  final bool canReduceActivity;

  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final String serverTime;

  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityResponse &&
          other.version == version &&
          other.acceptingToday == acceptingToday &&
          other.deliveryPaused == deliveryPaused &&
          other.deliveryPausedUntil == deliveryPausedUntil &&
          other.canResume == canResume &&
          other.canReduceActivity == canReduceActivity &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate;

  @override
  int get hashCode =>
      version.hashCode +
      acceptingToday.hashCode +
      deliveryPaused.hashCode +
      (deliveryPausedUntil == null ? 0 : deliveryPausedUntil.hashCode) +
      canResume.hashCode +
      canReduceActivity.hashCode +
      serverTime.hashCode +
      businessDate.hashCode;

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AvailabilityResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
