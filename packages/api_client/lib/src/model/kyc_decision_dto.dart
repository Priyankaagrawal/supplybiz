//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'kyc_decision_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KycDecisionDto {
  /// Returns a new [KycDecisionDto] instance.
  KycDecisionDto({
    required this.decision,
    required this.reason,
  });

  @JsonKey(
    name: r'decision',
    required: true,
    includeIfNull: false,
  )
  final KycDecisionDtoDecisionEnum decision;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KycDecisionDto &&
          other.decision == decision &&
          other.reason == reason;

  @override
  int get hashCode => decision.hashCode + reason.hashCode;

  factory KycDecisionDto.fromJson(Map<String, dynamic> json) =>
      _$KycDecisionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$KycDecisionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum KycDecisionDtoDecisionEnum {
  @JsonValue(r'VERIFIED')
  VERIFIED(r'VERIFIED'),
  @JsonValue(r'REJECTED')
  REJECTED(r'REJECTED');

  const KycDecisionDtoDecisionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
