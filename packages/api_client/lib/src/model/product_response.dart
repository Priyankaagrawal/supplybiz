//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'product_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProductResponse {
  /// Returns a new [ProductResponse] instance.
  ProductResponse({
    required this.id,
    required this.name,
    required this.productType,
    required this.milkType,
    required this.unitValue,
    required this.unitType,
    required this.sellingPricePaise,
    required this.subscriptionPricePaise,
    required this.stockQty,
    required this.moq,
    required this.description,
    required this.imageMediaId,
    required this.isActive,
    required this.version,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'productType',
    required: true,
    includeIfNull: false,
  )
  final String productType;

  @JsonKey(
    name: r'milkType',
    required: true,
    includeIfNull: true,
  )
  final String? milkType;

  @JsonKey(
    name: r'unitValue',
    required: true,
    includeIfNull: false,
  )
  final num unitValue;

  @JsonKey(
    name: r'unitType',
    required: true,
    includeIfNull: false,
  )
  final ProductResponseUnitTypeEnum unitType;

  @JsonKey(
    name: r'sellingPricePaise',
    required: true,
    includeIfNull: false,
  )
  final int sellingPricePaise;

  @JsonKey(
    name: r'subscriptionPricePaise',
    required: true,
    includeIfNull: true,
  )
  final int? subscriptionPricePaise;

  @JsonKey(
    name: r'stockQty',
    required: true,
    includeIfNull: false,
  )
  final int stockQty;

  @JsonKey(
    name: r'moq',
    required: true,
    includeIfNull: false,
  )
  final int moq;

  @JsonKey(
    name: r'description',
    required: true,
    includeIfNull: false,
  )
  final String description;

  @JsonKey(
    name: r'imageMediaId',
    required: true,
    includeIfNull: true,
  )
  final String? imageMediaId;

  @JsonKey(
    name: r'isActive',
    required: true,
    includeIfNull: false,
  )
  final bool isActive;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductResponse &&
          other.id == id &&
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
          other.version == version;

  @override
  int get hashCode =>
      id.hashCode +
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
      version.hashCode;

  factory ProductResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProductResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProductResponseUnitTypeEnum {
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

  const ProductResponseUnitTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
