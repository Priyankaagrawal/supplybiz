//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'device_push_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DevicePushInput {
  /// Returns a new [DevicePushInput] instance.
  DevicePushInput({
    this.pushToken,
    required this.pushEnabled,
    this.appVersion,
    this.osVersion,
  });

  /// Required when enabled. Null/omission with pushEnabled=false removes the current token. Never echoed.
  @JsonKey(
    name: r'pushToken',
    required: false,
    includeIfNull: false,
  )
  final String? pushToken;

  @JsonKey(
    name: r'pushEnabled',
    required: true,
    includeIfNull: false,
  )
  final bool pushEnabled;

  @JsonKey(
    name: r'appVersion',
    required: false,
    includeIfNull: false,
  )
  final String? appVersion;

  @JsonKey(
    name: r'osVersion',
    required: false,
    includeIfNull: false,
  )
  final String? osVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicePushInput &&
          other.pushToken == pushToken &&
          other.pushEnabled == pushEnabled &&
          other.appVersion == appVersion &&
          other.osVersion == osVersion;

  @override
  int get hashCode =>
      (pushToken == null ? 0 : pushToken.hashCode) +
      pushEnabled.hashCode +
      appVersion.hashCode +
      osVersion.hashCode;

  factory DevicePushInput.fromJson(Map<String, dynamic> json) =>
      _$DevicePushInputFromJson(json);

  Map<String, dynamic> toJson() => _$DevicePushInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
