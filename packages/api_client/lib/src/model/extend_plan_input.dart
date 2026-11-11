//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'extend_plan_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExtendPlanInput {
  /// Returns a new [ExtendPlanInput] instance.
  ExtendPlanInput({
    required this.endsAt,
    required this.reason,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtendPlanInput &&
          other.endsAt == endsAt &&
          other.reason == reason;

  @override
  int get hashCode => endsAt.hashCode + reason.hashCode;

  factory ExtendPlanInput.fromJson(Map<String, dynamic> json) =>
      _$ExtendPlanInputFromJson(json);

  Map<String, dynamic> toJson() => _$ExtendPlanInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
