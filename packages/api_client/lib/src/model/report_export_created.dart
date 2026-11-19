//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'report_export_created.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportExportCreated {
  /// Returns a new [ReportExportCreated] instance.
  ReportExportCreated({
    required this.exportId,
  });

  @JsonKey(
    name: r'exportId',
    required: true,
    includeIfNull: false,
  )
  final String exportId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportExportCreated && other.exportId == exportId;

  @override
  int get hashCode => exportId.hashCode;

  factory ReportExportCreated.fromJson(Map<String, dynamic> json) =>
      _$ReportExportCreatedFromJson(json);

  Map<String, dynamic> toJson() => _$ReportExportCreatedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
