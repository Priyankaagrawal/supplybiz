//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'reorder_unavailable.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReorderUnavailable {
  /// Returns a new [ReorderUnavailable] instance.
  ReorderUnavailable({
    required this.productId,
    required this.name,
    required this.reason,
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
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final ReorderUnavailableReasonEnum reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReorderUnavailable &&
          other.productId == productId &&
          other.name == name &&
          other.reason == reason;

  @override
  int get hashCode => productId.hashCode + name.hashCode + reason.hashCode;

  factory ReorderUnavailable.fromJson(Map<String, dynamic> json) =>
      _$ReorderUnavailableFromJson(json);

  Map<String, dynamic> toJson() => _$ReorderUnavailableToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ReorderUnavailableReasonEnum {
  @JsonValue(r'PRODUCT_UNAVAILABLE')
  PRODUCT_UNAVAILABLE(r'PRODUCT_UNAVAILABLE'),
  @JsonValue(r'BELOW_MOQ')
  BELOW_MOQ(r'BELOW_MOQ'),
  @JsonValue(r'INSUFFICIENT_STOCK')
  INSUFFICIENT_STOCK(r'INSUFFICIENT_STOCK');

  const ReorderUnavailableReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
