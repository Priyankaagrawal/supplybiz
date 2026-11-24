//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subject_export_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubjectExportResponse {
  /// Returns a new [SubjectExportResponse] instance.
  SubjectExportResponse({
    required this.filename,
    required this.json,
  });

  @JsonKey(
    name: r'filename',
    required: true,
    includeIfNull: false,
  )
  final String filename;

  @JsonKey(
    name: r'json',
    required: true,
    includeIfNull: false,
  )
  final String json;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectExportResponse &&
          other.filename == filename &&
          other.json == json;

  @override
  int get hashCode => filename.hashCode + json.hashCode;

  factory SubjectExportResponse.fromJson(Map<String, dynamic> json) =>
      _$SubjectExportResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectExportResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
