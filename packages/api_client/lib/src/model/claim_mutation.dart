//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'claim_mutation.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClaimMutation {
  /// Returns a new [ClaimMutation] instance.
  ClaimMutation({
    required this.id,
    required this.status,
    required this.version,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimMutation &&
          other.id == id &&
          other.status == status &&
          other.version == version;

  @override
  int get hashCode => id.hashCode + status.hashCode + version.hashCode;

  factory ClaimMutation.fromJson(Map<String, dynamic> json) =>
      _$ClaimMutationFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimMutationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
