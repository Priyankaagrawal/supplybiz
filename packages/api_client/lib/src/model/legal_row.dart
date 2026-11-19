//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'legal_row.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LegalRow {
  /// Returns a new [LegalRow] instance.
  LegalRow({
    required this.type,
    required this.version,
    required this.title,
    required this.text,
    required this.sha256,
    required this.publishedAt,
  });

  @JsonKey(
    name: r'type',
    required: true,
    includeIfNull: false,
  )
  final LegalRowTypeEnum type;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final String version;

  @JsonKey(
    name: r'title',
    required: true,
    includeIfNull: false,
  )
  final String title;

  @JsonKey(
    name: r'text',
    required: true,
    includeIfNull: false,
  )
  final String text;

  @JsonKey(
    name: r'sha256',
    required: true,
    includeIfNull: false,
  )
  final String sha256;

  @JsonKey(
    name: r'publishedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime publishedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalRow &&
          other.type == type &&
          other.version == version &&
          other.title == title &&
          other.text == text &&
          other.sha256 == sha256 &&
          other.publishedAt == publishedAt;

  @override
  int get hashCode =>
      type.hashCode +
      version.hashCode +
      title.hashCode +
      text.hashCode +
      sha256.hashCode +
      publishedAt.hashCode;

  factory LegalRow.fromJson(Map<String, dynamic> json) =>
      _$LegalRowFromJson(json);

  Map<String, dynamic> toJson() => _$LegalRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum LegalRowTypeEnum {
  @JsonValue(r'TERMS')
  TERMS(r'TERMS'),
  @JsonValue(r'PRIVACY')
  PRIVACY(r'PRIVACY');

  const LegalRowTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
