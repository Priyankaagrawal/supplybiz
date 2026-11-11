//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'assign_plan_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssignPlanInput {
  /// Returns a new [AssignPlanInput] instance.
  AssignPlanInput({
    required this.endsAt,
    required this.reason,
    required this.planId,
    required this.startsAt,
  });

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
    name: r'planId',
    required: true,
    includeIfNull: false,
  )
  final String planId;

  @JsonKey(
    name: r'startsAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime startsAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignPlanInput &&
          other.endsAt == endsAt &&
          other.reason == reason &&
          other.planId == planId &&
          other.startsAt == startsAt;

  @override
  int get hashCode =>
      endsAt.hashCode + reason.hashCode + planId.hashCode + startsAt.hashCode;

  factory AssignPlanInput.fromJson(Map<String, dynamic> json) =>
      _$AssignPlanInputFromJson(json);

  Map<String, dynamic> toJson() => _$AssignPlanInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
