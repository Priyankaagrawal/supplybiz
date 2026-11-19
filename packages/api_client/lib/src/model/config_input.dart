//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'config_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConfigInput {
  /// Returns a new [ConfigInput] instance.
  ConfigInput({
    required this.expectedUpdatedAt,
    required this.minVersionAndroid,
    required this.flags,
  });

  @JsonKey(
    name: r'expectedUpdatedAt',
    required: true,
    includeIfNull: true,
  )
  final String? expectedUpdatedAt;

  @JsonKey(
    name: r'minVersionAndroid',
    required: true,
    includeIfNull: false,
  )
  final String minVersionAndroid;

  /// Up to 50 simple presentation flags. Never grants permissions or entitlements.
  @JsonKey(
    name: r'flags',
    required: true,
    includeIfNull: false,
  )
  final Map<String, bool> flags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigInput &&
          other.expectedUpdatedAt == expectedUpdatedAt &&
          other.minVersionAndroid == minVersionAndroid &&
          other.flags == flags;

  @override
  int get hashCode =>
      (expectedUpdatedAt == null ? 0 : expectedUpdatedAt.hashCode) +
      minVersionAndroid.hashCode +
      flags.hashCode;

  factory ConfigInput.fromJson(Map<String, dynamic> json) =>
      _$ConfigInputFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
