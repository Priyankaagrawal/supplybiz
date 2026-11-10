//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/product_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProductList {
  /// Returns a new [ProductList] instance.
  ProductList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<ProductResponse> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductList && other.items == items && other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory ProductList.fromJson(Map<String, dynamic> json) =>
      _$ProductListFromJson(json);

  Map<String, dynamic> toJson() => _$ProductListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
