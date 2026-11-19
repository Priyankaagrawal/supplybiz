//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'faq_row.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FaqRow {
  /// Returns a new [FaqRow] instance.
  FaqRow({
    required this.id,
    required this.topic,
    required this.question,
    required this.answer,
    required this.published,
    required this.updatedAt,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

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

  @JsonKey(
    name: r'updatedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaqRow &&
          other.id == id &&
          other.topic == topic &&
          other.question == question &&
          other.answer == answer &&
          other.published == published &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      id.hashCode +
      topic.hashCode +
      question.hashCode +
      answer.hashCode +
      published.hashCode +
      updatedAt.hashCode;

  factory FaqRow.fromJson(Map<String, dynamic> json) => _$FaqRowFromJson(json);

  Map<String, dynamic> toJson() => _$FaqRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
