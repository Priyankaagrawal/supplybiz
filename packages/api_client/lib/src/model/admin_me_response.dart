//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'admin_me_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMeResponse {
  /// Returns a new [AdminMeResponse] instance.
  AdminMeResponse({
    required this.id,
    required this.role,
    required this.permissions,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'role',
    required: true,
    includeIfNull: false,
  )
  final String role;

  @JsonKey(
    name: r'permissions',
    required: true,
    includeIfNull: false,
  )
  final List<String> permissions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminMeResponse &&
          other.id == id &&
          other.role == role &&
          other.permissions == permissions;

  @override
  int get hashCode => id.hashCode + role.hashCode + permissions.hashCode;

  factory AdminMeResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminMeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMeResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
