//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'claim_rejection.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClaimRejection {
  /// Returns a new [ClaimRejection] instance.
  ClaimRejection({
    required this.version,
    required this.reason,
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
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimRejection &&
          other.version == version &&
          other.reason == reason;

  @override
  int get hashCode => version.hashCode + reason.hashCode;

  factory ClaimRejection.fromJson(Map<String, dynamic> json) =>
      _$ClaimRejectionFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimRejectionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
