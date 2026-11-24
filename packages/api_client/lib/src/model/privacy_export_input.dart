//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'privacy_export_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PrivacyExportInput {
  /// Returns a new [PrivacyExportInput] instance.
  PrivacyExportInput({
    required this.userId,
    required this.identityVerified,
    required this.reason,
  });

  @JsonKey(
    name: r'userId',
    required: true,
    includeIfNull: false,
  )
  final String userId;

  @JsonKey(
    name: r'identityVerified',
    required: true,
    includeIfNull: false,
  )
  final bool identityVerified;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacyExportInput &&
          other.userId == userId &&
          other.identityVerified == identityVerified &&
          other.reason == reason;

  @override
  int get hashCode =>
      userId.hashCode + identityVerified.hashCode + reason.hashCode;

  factory PrivacyExportInput.fromJson(Map<String, dynamic> json) =>
      _$PrivacyExportInputFromJson(json);

  Map<String, dynamic> toJson() => _$PrivacyExportInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
