//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'assignment_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssignmentResponse {
  /// Returns a new [AssignmentResponse] instance.
  AssignmentResponse({
    required this.id,
    required this.vendorId,
    required this.planId,
    required this.code,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.grantedByAdmin,
    required this.auditId,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'planId',
    required: true,
    includeIfNull: false,
  )
  final String planId;

  @JsonKey(
    name: r'code',
    required: true,
    includeIfNull: false,
  )
  final String code;

  @JsonKey(
    name: r'startsAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime startsAt;

  @JsonKey(
    name: r'endsAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime endsAt;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @JsonKey(
    name: r'grantedByAdmin',
    required: true,
    includeIfNull: false,
  )
  final String grantedByAdmin;

  @JsonKey(
    name: r'auditId',
    required: true,
    includeIfNull: false,
  )
  final String auditId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignmentResponse &&
          other.id == id &&
          other.vendorId == vendorId &&
          other.planId == planId &&
          other.code == code &&
          other.startsAt == startsAt &&
          other.endsAt == endsAt &&
          other.reason == reason &&
          other.grantedByAdmin == grantedByAdmin &&
          other.auditId == auditId;

  @override
  int get hashCode =>
      id.hashCode +
      vendorId.hashCode +
      planId.hashCode +
      code.hashCode +
      startsAt.hashCode +
      endsAt.hashCode +
      reason.hashCode +
      grantedByAdmin.hashCode +
      auditId.hashCode;

  factory AssignmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AssignmentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
