//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'delivery_impact.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeliveryImpact {
  /// Returns a new [DeliveryImpact] instance.
  DeliveryImpact({
    required this.affectedOrders,
    required this.serverTime,
    required this.businessDate,
  });

  /// Only NEW/ACCEPTED/PREPARING; preview is rechecked atomically on write.
  @JsonKey(
    name: r'affectedOrders',
    required: true,
    includeIfNull: false,
  )
  final int affectedOrders;

  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final String serverTime;

  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryImpact &&
          other.affectedOrders == affectedOrders &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate;

  @override
  int get hashCode =>
      affectedOrders.hashCode + serverTime.hashCode + businessDate.hashCode;

  factory DeliveryImpact.fromJson(Map<String, dynamic> json) =>
      _$DeliveryImpactFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryImpactToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
