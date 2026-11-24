//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'privacy_request_row.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PrivacyRequestRow {
  /// Returns a new [PrivacyRequestRow] instance.
  PrivacyRequestRow({
    required this.id,
    required this.userId,
    required this.kind,
    required this.status,
    required this.createdAt,
    required this.deadline,
    required this.reason,
    required this.version,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'userId',
    required: true,
    includeIfNull: false,
  )
  final String userId;

  @JsonKey(
    name: r'kind',
    required: true,
    includeIfNull: false,
  )
  final String kind;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )
  final String createdAt;

  @JsonKey(
    name: r'deadline',
    required: true,
    includeIfNull: false,
  )
  final String deadline;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: true,
  )
  final String? reason;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final num version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacyRequestRow &&
          other.id == id &&
          other.userId == userId &&
          other.kind == kind &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.deadline == deadline &&
          other.reason == reason &&
          other.version == version;

  @override
  int get hashCode =>
      id.hashCode +
      userId.hashCode +
      kind.hashCode +
      status.hashCode +
      createdAt.hashCode +
      deadline.hashCode +
      (reason == null ? 0 : reason.hashCode) +
      version.hashCode;

  factory PrivacyRequestRow.fromJson(Map<String, dynamic> json) =>
      _$PrivacyRequestRowFromJson(json);

  Map<String, dynamic> toJson() => _$PrivacyRequestRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
