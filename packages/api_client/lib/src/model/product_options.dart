//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'product_options.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProductOptions {
  /// Returns a new [ProductOptions] instance.
  ProductOptions({
    required this.productTypes,
  });

  /// Admin-managed product type codes for the signed-in vendor category.
  @JsonKey(
    name: r'productTypes',
    required: true,
    includeIfNull: false,
  )
  final List<String> productTypes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductOptions && other.productTypes == productTypes;

  @override
  int get hashCode => productTypes.hashCode;

  factory ProductOptions.fromJson(Map<String, dynamic> json) =>
      _$ProductOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$ProductOptionsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
