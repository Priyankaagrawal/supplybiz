//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'order_priced_line.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderPricedLine {
  /// Returns a new [OrderPricedLine] instance.
  OrderPricedLine({
    required this.productId,
    required this.name,
    required this.unitValue,
    required this.unitType,
    required this.qty,
    required this.unitPricePaise,
    required this.lineTotalPaise,
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
    name: r'unitPricePaise',
    required: true,
    includeIfNull: false,
  )
  final String unitPricePaise;

  @JsonKey(
    name: r'lineTotalPaise',
    required: true,
    includeIfNull: false,
  )
  final String lineTotalPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderPricedLine &&
          other.productId == productId &&
          other.name == name &&
          other.unitValue == unitValue &&
          other.unitType == unitType &&
          other.qty == qty &&
          other.unitPricePaise == unitPricePaise &&
          other.lineTotalPaise == lineTotalPaise;

  @override
  int get hashCode =>
      productId.hashCode +
      name.hashCode +
      unitValue.hashCode +
      unitType.hashCode +
      qty.hashCode +
      unitPricePaise.hashCode +
      lineTotalPaise.hashCode;

  factory OrderPricedLine.fromJson(Map<String, dynamic> json) =>
      _$OrderPricedLineFromJson(json);

  Map<String, dynamic> toJson() => _$OrderPricedLineToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
