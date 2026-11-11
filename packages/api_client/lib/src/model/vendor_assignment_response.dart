//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_assignment_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorAssignmentResponse {
  /// Returns a new [VendorAssignmentResponse] instance.
  VendorAssignmentResponse({
    required this.id,
    required this.planId,
    required this.code,
    required this.startsAt,
    required this.endsAt,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorAssignmentResponse &&
          other.id == id &&
          other.planId == planId &&
          other.code == code &&
          other.startsAt == startsAt &&
          other.endsAt == endsAt;

  @override
  int get hashCode =>
      id.hashCode +
      planId.hashCode +
      code.hashCode +
      startsAt.hashCode +
      endsAt.hashCode;

  factory VendorAssignmentResponse.fromJson(Map<String, dynamic> json) =>
      _$VendorAssignmentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VendorAssignmentResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
