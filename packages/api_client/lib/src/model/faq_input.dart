//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'faq_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FaqInput {
  /// Returns a new [FaqInput] instance.
  FaqInput({
    required this.expectedUpdatedAt,
    required this.topic,
    required this.question,
    required this.answer,
    required this.published,
  });

  /// Null when creating; otherwise exact server updatedAt.
  @JsonKey(
    name: r'expectedUpdatedAt',
    required: true,
    includeIfNull: true,
  )
  final String? expectedUpdatedAt;

  @JsonKey(
    name: r'topic',
    required: true,
    includeIfNull: false,
  )
  final String topic;

  @JsonKey(
    name: r'question',
    required: true,
    includeIfNull: false,
  )
  final String question;

  /// Plaintext only; clients must render as text, never HTML.
  @JsonKey(
    name: r'answer',
    required: true,
    includeIfNull: false,
  )
  final String answer;

  @JsonKey(
    name: r'published',
    required: true,
    includeIfNull: false,
  )
  final bool published;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaqInput &&
          other.expectedUpdatedAt == expectedUpdatedAt &&
          other.topic == topic &&
          other.question == question &&
          other.answer == answer &&
          other.published == published;

  @override
  int get hashCode =>
      (expectedUpdatedAt == null ? 0 : expectedUpdatedAt.hashCode) +
      topic.hashCode +
      question.hashCode +
      answer.hashCode +
      published.hashCode;

  factory FaqInput.fromJson(Map<String, dynamic> json) =>
      _$FaqInputFromJson(json);

  Map<String, dynamic> toJson() => _$FaqInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
