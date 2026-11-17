//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'sale_item_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaleItemResponse {
  /// Returns a new [SaleItemResponse] instance.
  SaleItemResponse({
    required this.productId,
    required this.name,
    required this.unitValue,
    required this.unitType,
    required this.qty,
    required this.ratePaise,
    required this.amountPaise,
  });

  @JsonKey(
    name: r'productId',
    required: true,
    includeIfNull: false,
  )
  final String productId;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'unitValue',
    required: true,
    includeIfNull: false,
  )
  final String unitValue;

  @JsonKey(
    name: r'unitType',
    required: true,
    includeIfNull: false,
  )
  final String unitType;

  @JsonKey(
    name: r'qty',
    required: true,
    includeIfNull: false,
  )
  final int qty;

  @JsonKey(
    name: r'ratePaise',
    required: true,
    includeIfNull: false,
  )
  final String ratePaise;

  @JsonKey(
    name: r'amountPaise',
    required: true,
    includeIfNull: false,
  )
  final String amountPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleItemResponse &&
          other.productId == productId &&
          other.name == name &&
          other.unitValue == unitValue &&
          other.unitType == unitType &&
          other.qty == qty &&
          other.ratePaise == ratePaise &&
          other.amountPaise == amountPaise;

  @override
  int get hashCode =>
      productId.hashCode +
      name.hashCode +
      unitValue.hashCode +
      unitType.hashCode +
      qty.hashCode +
      ratePaise.hashCode +
      amountPaise.hashCode;

  factory SaleItemResponse.fromJson(Map<String, dynamic> json) =>
      _$SaleItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SaleItemResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
