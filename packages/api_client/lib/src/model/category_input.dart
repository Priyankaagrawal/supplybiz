//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'category_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CategoryInput {
  /// Returns a new [CategoryInput] instance.
  CategoryInput({
    required this.code,
    required this.name,
    required this.icon,
    required this.type,
    required this.status,
    required this.sortOrder,
    required this.productTypes,
  });

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

  /// Icon identifier, not a URL or HTML. Empty clears the icon.
  @JsonKey(
    name: r'icon',
    required: true,
    includeIfNull: false,
  )
  final String icon;

  @JsonKey(
    name: r'type',
    required: true,
    includeIfNull: false,
  )
  final CategoryInputTypeEnum type;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final CategoryInputStatusEnum status;

  @JsonKey(
    name: r'sortOrder',
    required: true,
    includeIfNull: false,
  )
  final num sortOrder;

  @JsonKey(
    name: r'productTypes',
    required: true,
    includeIfNull: false,
  )
  final List<String> productTypes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryInput &&
          other.code == code &&
          other.name == name &&
          other.icon == icon &&
          other.type == type &&
          other.status == status &&
          other.sortOrder == sortOrder &&
          other.productTypes == productTypes;

  @override
  int get hashCode =>
      code.hashCode +
      name.hashCode +
      icon.hashCode +
      type.hashCode +
      status.hashCode +
      sortOrder.hashCode +
      productTypes.hashCode;

  factory CategoryInput.fromJson(Map<String, dynamic> json) =>
      _$CategoryInputFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CategoryInputTypeEnum {
  @JsonValue(r'SUPPLY')
  SUPPLY(r'SUPPLY'),
  @JsonValue(r'BILL')
  BILL(r'BILL');

  const CategoryInputTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum CategoryInputStatusEnum {
  @JsonValue(r'ENABLED')
  ENABLED(r'ENABLED'),
  @JsonValue(r'COMING_SOON')
  COMING_SOON(r'COMING_SOON'),
  @JsonValue(r'HIDDEN')
  HIDDEN(r'HIDDEN');

  const CategoryInputStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
