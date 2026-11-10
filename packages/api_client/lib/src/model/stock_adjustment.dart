//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'stock_adjustment.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StockAdjustment {
  /// Returns a new [StockAdjustment] instance.
  StockAdjustment({
    required this.delta,
    required this.reason,
  });

  /// Nonzero pack delta.
  @JsonKey(
    name: r'delta',
    required: true,
    includeIfNull: false,
  )
  final int delta;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockAdjustment &&
          other.delta == delta &&
          other.reason == reason;

  @override
  int get hashCode => delta.hashCode + reason.hashCode;

  factory StockAdjustment.fromJson(Map<String, dynamic> json) =>
      _$StockAdjustmentFromJson(json);

  Map<String, dynamic> toJson() => _$StockAdjustmentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
