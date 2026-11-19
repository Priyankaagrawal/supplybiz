//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'platform_export_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlatformExportInput {
  /// Returns a new [PlatformExportInput] instance.
  PlatformExportInput({
    required this.kind,
  });

  @JsonKey(
    name: r'kind',
    required: true,
    includeIfNull: false,
  )
  final PlatformExportInputKindEnum kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformExportInput && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;

  factory PlatformExportInput.fromJson(Map<String, dynamic> json) =>
      _$PlatformExportInputFromJson(json);

  Map<String, dynamic> toJson() => _$PlatformExportInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PlatformExportInputKindEnum {
  @JsonValue(r'PLATFORM_SUMMARY')
  PLATFORM_SUMMARY(r'PLATFORM_SUMMARY');

  const PlatformExportInputKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
