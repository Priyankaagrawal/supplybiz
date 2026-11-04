//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'admin_session_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminSessionResponse {
  /// Returns a new [AdminSessionResponse] instance.
  AdminSessionResponse({
    required this.sessionToken,
    required this.csrfToken,
  });

  @JsonKey(
    name: r'sessionToken',
    required: true,
    includeIfNull: false,
  )
  final String sessionToken;

  @JsonKey(
    name: r'csrfToken',
    required: true,
    includeIfNull: false,
  )
  final String csrfToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminSessionResponse &&
          other.sessionToken == sessionToken &&
          other.csrfToken == csrfToken;

  @override
  int get hashCode => sessionToken.hashCode + csrfToken.hashCode;

  factory AdminSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminSessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSessionResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
