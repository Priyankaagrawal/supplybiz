//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'platform_export_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlatformExportResponse {
  /// Returns a new [PlatformExportResponse] instance.
  PlatformExportResponse({
    required this.filename,
    required this.csv,
    required this.snapshotAt,
  });

  @JsonKey(
    name: r'filename',
    required: true,
    includeIfNull: false,
  )
  final String filename;

  @JsonKey(
    name: r'csv',
    required: true,
    includeIfNull: false,
  )
  final String csv;

  @JsonKey(
    name: r'snapshotAt',
    required: true,
    includeIfNull: false,
  )
  final String snapshotAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformExportResponse &&
          other.filename == filename &&
          other.csv == csv &&
          other.snapshotAt == snapshotAt;

  @override
  int get hashCode => filename.hashCode + csv.hashCode + snapshotAt.hashCode;

  factory PlatformExportResponse.fromJson(Map<String, dynamic> json) =>
      _$PlatformExportResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlatformExportResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
