//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'privacy_hold_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PrivacyHoldInput {
  /// Returns a new [PrivacyHoldInput] instance.
  PrivacyHoldInput({
    required this.action,
    required this.expectedVersion,
    required this.reason,
  });

  @JsonKey(
    name: r'action',
    required: true,
    includeIfNull: false,
  )
  final PrivacyHoldInputActionEnum action;

  @JsonKey(
    name: r'expectedVersion',
    required: true,
    includeIfNull: false,
  )
  final num expectedVersion;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacyHoldInput &&
          other.action == action &&
          other.expectedVersion == expectedVersion &&
          other.reason == reason;

  @override
  int get hashCode =>
      action.hashCode + expectedVersion.hashCode + reason.hashCode;

  factory PrivacyHoldInput.fromJson(Map<String, dynamic> json) =>
      _$PrivacyHoldInputFromJson(json);

  Map<String, dynamic> toJson() => _$PrivacyHoldInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PrivacyHoldInputActionEnum {
  @JsonValue(r'HOLD')
  HOLD(r'HOLD'),
  @JsonValue(r'RELEASE')
  RELEASE(r'RELEASE');

  const PrivacyHoldInputActionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
