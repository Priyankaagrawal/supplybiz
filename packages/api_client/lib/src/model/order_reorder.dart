//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/reorder_unavailable.dart';
import 'package:supplybiz_api_client/src/model/reorder_line.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_reorder.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderReorder {
  /// Returns a new [OrderReorder] instance.
  OrderReorder({
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.unavailable,
  });

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'vendorName',
    required: true,
    includeIfNull: false,
  )
  final String vendorName;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<ReorderLine> items;

  @JsonKey(
    name: r'unavailable',
    required: true,
    includeIfNull: false,
  )
  final List<ReorderUnavailable> unavailable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderReorder &&
          other.vendorId == vendorId &&
          other.vendorName == vendorName &&
          other.items == items &&
          other.unavailable == unavailable;

  @override
  int get hashCode =>
      vendorId.hashCode +
      vendorName.hashCode +
      items.hashCode +
      unavailable.hashCode;

  factory OrderReorder.fromJson(Map<String, dynamic> json) =>
      _$OrderReorderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderReorderToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
