//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'sale_line_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaleLineInput {
  /// Returns a new [SaleLineInput] instance.
  SaleLineInput({
    required this.productId,
    required this.qty,
    this.ratePaise,
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

  /// Authorized vendor rate override in paise; omitted uses current selling price. Max signed BIGINT.
  @JsonKey(
    name: r'ratePaise',
    required: false,
    includeIfNull: false,
  )
  final String? ratePaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleLineInput &&
          other.productId == productId &&
          other.qty == qty &&
          other.ratePaise == ratePaise;

  @override
  int get hashCode => productId.hashCode + qty.hashCode + ratePaise.hashCode;

  factory SaleLineInput.fromJson(Map<String, dynamic> json) =>
      _$SaleLineInputFromJson(json);

  Map<String, dynamic> toJson() => _$SaleLineInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
