//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'product_patch.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProductPatch {
  /// Returns a new [ProductPatch] instance.
  ProductPatch({
    this.name,
    this.productType,
    this.milkType,
    this.unitValue,
    this.unitType,
    this.sellingPricePaise,
    this.subscriptionPricePaise,
    this.stockQty = 0,
    this.moq = 1,
    this.description = '',
    this.imageMediaId,
    this.isActive = true,
    this.stockReason,
  });

  @JsonKey(
    name: r'name',
    required: false,
    includeIfNull: false,
  )
  final String? name;

  /// One of the vendor category productTypes (admin-managed).
  @JsonKey(
    name: r'productType',
    required: false,
    includeIfNull: false,
  )
  final String? productType;

  @JsonKey(
    name: r'milkType',
    required: false,
    includeIfNull: false,
  )
  final ProductPatchMilkTypeEnum? milkType;

  // minimum: 0.001
  // maximum: 999999999.999
  @JsonKey(
    name: r'unitValue',
    required: false,
    includeIfNull: false,
  )
  final num? unitValue;

  @JsonKey(
    name: r'unitType',
    required: false,
    includeIfNull: false,
  )
  final ProductPatchUnitTypeEnum? unitType;

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'sellingPricePaise',
    required: false,
    includeIfNull: false,
  )
  final int? sellingPricePaise;

  // minimum: 0
  // maximum: 2147483647
  @JsonKey(
    name: r'subscriptionPricePaise',
    required: false,
    includeIfNull: false,
  )
  final int? subscriptionPricePaise;

  // minimum: 0
  // maximum: 2147483647
  @JsonKey(
    defaultValue: 0,
    name: r'stockQty',
    required: false,
    includeIfNull: false,
  )
  final int? stockQty;

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    defaultValue: 1,
    name: r'moq',
    required: false,
    includeIfNull: false,
  )
  final int? moq;

  @JsonKey(
    defaultValue: '',
    name: r'description',
    required: false,
    includeIfNull: false,
  )
  final String? description;

  @JsonKey(
    name: r'imageMediaId',
    required: false,
    includeIfNull: false,
  )
  final String? imageMediaId;

  @JsonKey(
    defaultValue: true,
    name: r'isActive',
    required: false,
    includeIfNull: false,
  )
  final bool? isActive;

  /// Required when changing stockQty.
  @JsonKey(
    name: r'stockReason',
    required: false,
    includeIfNull: false,
  )
  final String? stockReason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductPatch &&
          other.name == name &&
          other.productType == productType &&
          other.milkType == milkType &&
          other.unitValue == unitValue &&
          other.unitType == unitType &&
          other.sellingPricePaise == sellingPricePaise &&
          other.subscriptionPricePaise == subscriptionPricePaise &&
          other.stockQty == stockQty &&
          other.moq == moq &&
          other.description == description &&
          other.imageMediaId == imageMediaId &&
          other.isActive == isActive &&
          other.stockReason == stockReason;

  @override
  int get hashCode =>
      name.hashCode +
      productType.hashCode +
      (milkType == null ? 0 : milkType.hashCode) +
      unitValue.hashCode +
      unitType.hashCode +
      sellingPricePaise.hashCode +
      (subscriptionPricePaise == null ? 0 : subscriptionPricePaise.hashCode) +
      stockQty.hashCode +
      moq.hashCode +
      description.hashCode +
      (imageMediaId == null ? 0 : imageMediaId.hashCode) +
      isActive.hashCode +
      stockReason.hashCode;

  factory ProductPatch.fromJson(Map<String, dynamic> json) =>
      _$ProductPatchFromJson(json);

  Map<String, dynamic> toJson() => _$ProductPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProductPatchMilkTypeEnum {
  @JsonValue(r'COW')
  COW(r'COW'),
  @JsonValue(r'BUFFALO')
  BUFFALO(r'BUFFALO'),
  @JsonValue(r'TONED')
  TONED(r'TONED'),
  @JsonValue(r'DOUBLE_TONED')
  DOUBLE_TONED(r'DOUBLE_TONED'),
  @JsonValue(r'FULL_CREAM')
  FULL_CREAM(r'FULL_CREAM'),
  @JsonValue(r'OTHER')
  OTHER(r'OTHER');

  const ProductPatchMilkTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ProductPatchUnitTypeEnum {
  @JsonValue(r'ML')
  ML(r'ML'),
  @JsonValue(r'L')
  L(r'L'),
  @JsonValue(r'G')
  G(r'G'),
  @JsonValue(r'KG')
  KG(r'KG'),
  @JsonValue(r'PCS')
  PCS(r'PCS');

  const ProductPatchUnitTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
