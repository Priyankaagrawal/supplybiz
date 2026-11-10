//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/category_row.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CategoryList {
  /// Returns a new [CategoryList] instance.
  CategoryList({
    required this.items,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<CategoryRow> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryList && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory CategoryList.fromJson(Map<String, dynamic> json) =>
      _$CategoryListFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
