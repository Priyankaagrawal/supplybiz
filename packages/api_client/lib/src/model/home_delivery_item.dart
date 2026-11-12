//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'home_delivery_item.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeDeliveryItem {
  /// Returns a new [HomeDeliveryItem] instance.
  HomeDeliveryItem({
    required this.productId,
    required this.name,
    required this.qty,
  });

  @JsonKey(
    name: r'productId',
    required: true,
    includeIfNull: false,
  )
  final String productId;

  /// Persisted order-time name, including inactive/deleted products.
  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'qty',
    required: true,
    includeIfNull: false,
  )
  final int qty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeDeliveryItem &&
          other.productId == productId &&
          other.name == name &&
          other.qty == qty;

  @override
  int get hashCode => productId.hashCode + name.hashCode + qty.hashCode;

  factory HomeDeliveryItem.fromJson(Map<String, dynamic> json) =>
      _$HomeDeliveryItemFromJson(json);

  Map<String, dynamic> toJson() => _$HomeDeliveryItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
