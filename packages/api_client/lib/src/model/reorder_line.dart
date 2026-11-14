//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/product_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reorder_line.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReorderLine {
  /// Returns a new [ReorderLine] instance.
  ReorderLine({
    required this.product,
    required this.qty,
  });

  @JsonKey(
    name: r'product',
    required: true,
    includeIfNull: false,
  )
  final ProductResponse product;

  @JsonKey(
    name: r'qty',
    required: true,
    includeIfNull: false,
  )
  final int qty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReorderLine && other.product == product && other.qty == qty;

  @override
  int get hashCode => product.hashCode + qty.hashCode;

  factory ReorderLine.fromJson(Map<String, dynamic> json) =>
      _$ReorderLineFromJson(json);

  Map<String, dynamic> toJson() => _$ReorderLineToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
