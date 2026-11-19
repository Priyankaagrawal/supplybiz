//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'report_export_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportExportInput {
  /// Returns a new [ReportExportInput] instance.
  ReportExportInput({
    required this.from,
    required this.to,
    required this.format,
  });

  @JsonKey(
    name: r'from',
    required: true,
    includeIfNull: false,
  )
  final String from;

  @JsonKey(
    name: r'to',
    required: true,
    includeIfNull: false,
  )
  final String to;

  @JsonKey(
    name: r'format',
    required: true,
    includeIfNull: false,
  )
  final ReportExportInputFormatEnum format;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportExportInput &&
          other.from == from &&
          other.to == to &&
          other.format == format;

  @override
  int get hashCode => from.hashCode + to.hashCode + format.hashCode;

  factory ReportExportInput.fromJson(Map<String, dynamic> json) =>
      _$ReportExportInputFromJson(json);

  Map<String, dynamic> toJson() => _$ReportExportInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ReportExportInputFormatEnum {
  @JsonValue(r'CSV')
  CSV(r'CSV');

  const ReportExportInputFormatEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
