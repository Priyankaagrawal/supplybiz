//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_category_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorCategoryDto {
  /// Returns a new [VendorCategoryDto] instance.
  VendorCategoryDto({
    required this.categoryId,
  });

  @JsonKey(
    name: r'categoryId',
    required: true,
    includeIfNull: false,
  )
  final String categoryId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorCategoryDto && other.categoryId == categoryId;

  @override
  int get hashCode => categoryId.hashCode;

  factory VendorCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$VendorCategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VendorCategoryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
