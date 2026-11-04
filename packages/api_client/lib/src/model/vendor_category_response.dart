//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_category_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorCategoryResponse {
  /// Returns a new [VendorCategoryResponse] instance.
  VendorCategoryResponse({
    required this.id,
    required this.code,
    required this.name,
    required this.icon,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'code',
    required: true,
    includeIfNull: false,
  )
  final String code;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'icon',
    required: true,
    includeIfNull: true,
  )
  final String? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorCategoryResponse &&
          other.id == id &&
          other.code == code &&
          other.name == name &&
          other.icon == icon;

  @override
  int get hashCode =>
      id.hashCode +
      code.hashCode +
      name.hashCode +
      (icon == null ? 0 : icon.hashCode);

  factory VendorCategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$VendorCategoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VendorCategoryResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
