//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'admin_config_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminConfigResponse {
  /// Returns a new [AdminConfigResponse] instance.
  AdminConfigResponse({
    required this.minVersionAndroid,
    required this.flags,
    required this.updatedAt,
  });

  @JsonKey(
    name: r'minVersionAndroid',
    required: true,
    includeIfNull: false,
  )
  final String minVersionAndroid;

  @JsonKey(
    name: r'flags',
    required: true,
    includeIfNull: false,
  )
  final Map<String, bool> flags;

  @JsonKey(
    name: r'updatedAt',
    required: true,
    includeIfNull: true,
  )
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminConfigResponse &&
          other.minVersionAndroid == minVersionAndroid &&
          other.flags == flags &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      minVersionAndroid.hashCode +
      flags.hashCode +
      (updatedAt == null ? 0 : updatedAt.hashCode);

  factory AdminConfigResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminConfigResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminConfigResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
