//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'management_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagementResponse {
  /// Returns a new [ManagementResponse] instance.
  ManagementResponse({
    required this.id,
    required this.updatedAt,
    this.status,
    this.isSuspended,
    this.badges,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'updatedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @JsonKey(
    name: r'status',
    required: false,
    includeIfNull: false,
  )
  final String? status;

  @JsonKey(
    name: r'isSuspended',
    required: false,
    includeIfNull: false,
  )
  final bool? isSuspended;

  @JsonKey(
    name: r'badges',
    required: false,
    includeIfNull: false,
  )
  final List<String>? badges;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagementResponse &&
          other.id == id &&
          other.updatedAt == updatedAt &&
          other.status == status &&
          other.isSuspended == isSuspended &&
          other.badges == badges;

  @override
  int get hashCode =>
      id.hashCode +
      updatedAt.hashCode +
      status.hashCode +
      isSuspended.hashCode +
      badges.hashCode;

  factory ManagementResponse.fromJson(Map<String, dynamic> json) =>
      _$ManagementResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ManagementResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
