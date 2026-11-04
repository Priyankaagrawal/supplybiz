//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'version_controller_get_version200_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VersionControllerGetVersion200Response {
  /// Returns a new [VersionControllerGetVersion200Response] instance.
  VersionControllerGetVersion200Response({
    required this.service,
    required this.version,
    required this.nodeEnv,
    this.buildTime,
    this.gitSha,
  });

  @JsonKey(
    name: r'service',
    required: true,
    includeIfNull: false,
  )
  final String service;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final String version;

  @JsonKey(
    name: r'nodeEnv',
    required: true,
    includeIfNull: false,
  )
  final String nodeEnv;

  @JsonKey(
    name: r'buildTime',
    required: false,
    includeIfNull: false,
  )
  final String? buildTime;

  @JsonKey(
    name: r'gitSha',
    required: false,
    includeIfNull: false,
  )
  final String? gitSha;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersionControllerGetVersion200Response &&
          other.service == service &&
          other.version == version &&
          other.nodeEnv == nodeEnv &&
          other.buildTime == buildTime &&
          other.gitSha == gitSha;

  @override
  int get hashCode =>
      service.hashCode +
      version.hashCode +
      nodeEnv.hashCode +
      (buildTime == null ? 0 : buildTime.hashCode) +
      (gitSha == null ? 0 : gitSha.hashCode);

  factory VersionControllerGetVersion200Response.fromJson(
          Map<String, dynamic> json) =>
      _$VersionControllerGetVersion200ResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$VersionControllerGetVersion200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
