//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'device_push_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DevicePushResponse {
  /// Returns a new [DevicePushResponse] instance.
  DevicePushResponse({
    required this.deviceId,
    required this.pushEnabled,
  });

  @JsonKey(
    name: r'deviceId',
    required: true,
    includeIfNull: false,
  )
  final String deviceId;

  @JsonKey(
    name: r'pushEnabled',
    required: true,
    includeIfNull: false,
  )
  final bool pushEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicePushResponse &&
          other.deviceId == deviceId &&
          other.pushEnabled == pushEnabled;

  @override
  int get hashCode => deviceId.hashCode + pushEnabled.hashCode;

  factory DevicePushResponse.fromJson(Map<String, dynamic> json) =>
      _$DevicePushResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DevicePushResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
