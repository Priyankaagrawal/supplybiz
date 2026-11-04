//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'app_config_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppConfigResponse {
  /// Returns a new [AppConfigResponse] instance.
  AppConfigResponse({
    required this.minVersionAndroid,
    required this.flags,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigResponse &&
          other.minVersionAndroid == minVersionAndroid &&
          other.flags == flags;

  @override
  int get hashCode => minVersionAndroid.hashCode + flags.hashCode;

  factory AppConfigResponse.fromJson(Map<String, dynamic> json) =>
      _$AppConfigResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
