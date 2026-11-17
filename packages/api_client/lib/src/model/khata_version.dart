//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'khata_version.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KhataVersion {
  /// Returns a new [KhataVersion] instance.
  KhataVersion({
    required this.version,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhataVersion && other.version == version;

  @override
  int get hashCode => version.hashCode;

  factory KhataVersion.fromJson(Map<String, dynamic> json) =>
      _$KhataVersionFromJson(json);

  Map<String, dynamic> toJson() => _$KhataVersionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
