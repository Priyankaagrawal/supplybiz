//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'report_product.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportProduct {
  /// Returns a new [ReportProduct] instance.
  ReportProduct({
    required this.productId,
    required this.name,
    required this.unitValue,
    required this.unitType,
    required this.quantityPacks,
    required this.salesPaise,
  });

  @JsonKey(
    name: r'productId',
    required: true,
    includeIfNull: false,
  )
  final String productId;

  /// Immutable sold name; renamed/repacked products produce distinct snapshot groups.
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

  /// Integer packs, not litres. Exact aggregate string.
  @JsonKey(
    name: r'quantityPacks',
    required: true,
    includeIfNull: false,
  )
  final String quantityPacks;

  @JsonKey(
    name: r'salesPaise',
    required: true,
    includeIfNull: false,
  )
  final String salesPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportProduct &&
          other.productId == productId &&
          other.name == name &&
          other.unitValue == unitValue &&
          other.unitType == unitType &&
          other.quantityPacks == quantityPacks &&
          other.salesPaise == salesPaise;

  @override
  int get hashCode =>
      productId.hashCode +
      name.hashCode +
      unitValue.hashCode +
      unitType.hashCode +
      quantityPacks.hashCode +
      salesPaise.hashCode;

  factory ReportProduct.fromJson(Map<String, dynamic> json) =>
      _$ReportProductFromJson(json);

  Map<String, dynamic> toJson() => _$ReportProductToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
