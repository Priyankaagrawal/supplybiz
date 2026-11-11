//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'link_decision_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LinkDecisionResponse {
  /// Returns a new [LinkDecisionResponse] instance.
  LinkDecisionResponse({
    required this.id,
    required this.decision,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'decision',
    required: true,
    includeIfNull: false,
  )
  final LinkDecisionResponseDecisionEnum decision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkDecisionResponse &&
          other.id == id &&
          other.decision == decision;

  @override
  int get hashCode => id.hashCode + decision.hashCode;

  factory LinkDecisionResponse.fromJson(Map<String, dynamic> json) =>
      _$LinkDecisionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LinkDecisionResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum LinkDecisionResponseDecisionEnum {
  @JsonValue(r'ACCEPTED')
  ACCEPTED(r'ACCEPTED'),
  @JsonValue(r'DECLINED')
  DECLINED(r'DECLINED');

  const LinkDecisionResponseDecisionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
