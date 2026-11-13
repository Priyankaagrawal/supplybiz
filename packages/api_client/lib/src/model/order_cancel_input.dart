//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'order_cancel_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderCancelInput {
  /// Returns a new [OrderCancelInput] instance.
  OrderCancelInput({
    required this.version,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderCancelInput && other.version == version;

  @override
  int get hashCode => version.hashCode;

  factory OrderCancelInput.fromJson(Map<String, dynamic> json) =>
      _$OrderCancelInputFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCancelInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
