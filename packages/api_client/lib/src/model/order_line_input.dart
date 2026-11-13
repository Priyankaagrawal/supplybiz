//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'order_line_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderLineInput {
  /// Returns a new [OrderLineInput] instance.
  OrderLineInput({
    required this.productId,
    required this.qty,
  });

  @JsonKey(
    name: r'productId',
    required: true,
    includeIfNull: false,
  )
  final String productId;

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'qty',
    required: true,
    includeIfNull: false,
  )
  final int qty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderLineInput &&
          other.productId == productId &&
          other.qty == qty;

  @override
  int get hashCode => productId.hashCode + qty.hashCode;

  factory OrderLineInput.fromJson(Map<String, dynamic> json) =>
      _$OrderLineInputFromJson(json);

  Map<String, dynamic> toJson() => _$OrderLineInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
