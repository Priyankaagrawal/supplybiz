//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'legal_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LegalInput {
  /// Returns a new [LegalInput] instance.
  LegalInput({
    required this.expectedVersion,
    required this.version,
    required this.title,
    required this.text,
  });

  /// Current published version, or null for the first version.
  @JsonKey(
    name: r'expectedVersion',
    required: true,
    includeIfNull: true,
  )
  final String? expectedVersion;

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

  /// English plaintext; published versions cannot be overwritten.
  @JsonKey(
    name: r'text',
    required: true,
    includeIfNull: false,
  )
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalInput &&
          other.expectedVersion == expectedVersion &&
          other.version == version &&
          other.title == title &&
          other.text == text;

  @override
  int get hashCode =>
      (expectedVersion == null ? 0 : expectedVersion.hashCode) +
      version.hashCode +
      title.hashCode +
      text.hashCode;

  factory LegalInput.fromJson(Map<String, dynamic> json) =>
      _$LegalInputFromJson(json);

  Map<String, dynamic> toJson() => _$LegalInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
