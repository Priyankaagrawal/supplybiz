//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'health_controller_get_live200_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthControllerGetLive200Response {
  /// Returns a new [HealthControllerGetLive200Response] instance.
  HealthControllerGetLive200Response({
    required this.status,
    required this.timestamp,
  });

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'timestamp',
    required: true,
    includeIfNull: false,
  )
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthControllerGetLive200Response &&
          other.status == status &&
          other.timestamp == timestamp;

  @override
  int get hashCode => status.hashCode + timestamp.hashCode;

  factory HealthControllerGetLive200Response.fromJson(
          Map<String, dynamic> json) =>
      _$HealthControllerGetLive200ResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$HealthControllerGetLive200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
