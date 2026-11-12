//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'home_category.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeCategory {
  /// Returns a new [HomeCategory] instance.
  HomeCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.icon,
    required this.status,
    required this.available,
    required this.productTypes,
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

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final HomeCategoryStatusEnum status;

  @JsonKey(
    name: r'available',
    required: true,
    includeIfNull: false,
  )
  final bool available;

  @JsonKey(
    name: r'productTypes',
    required: true,
    includeIfNull: false,
  )
  final List<String> productTypes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeCategory &&
          other.id == id &&
          other.code == code &&
          other.name == name &&
          other.icon == icon &&
          other.status == status &&
          other.available == available &&
          other.productTypes == productTypes;

  @override
  int get hashCode =>
      id.hashCode +
      code.hashCode +
      name.hashCode +
      (icon == null ? 0 : icon.hashCode) +
      status.hashCode +
      available.hashCode +
      productTypes.hashCode;

  factory HomeCategory.fromJson(Map<String, dynamic> json) =>
      _$HomeCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$HomeCategoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HomeCategoryStatusEnum {
  @JsonValue(r'ENABLED')
  ENABLED(r'ENABLED'),
  @JsonValue(r'COMING_SOON')
  COMING_SOON(r'COMING_SOON');

  const HomeCategoryStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
