//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'delivery_counts.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeliveryCounts {
  /// Returns a new [DeliveryCounts] instance.
  DeliveryCounts({
    required this.ALL,
    required this.PENDING,
    required this.PREPARING,
    required this.OUT_FOR_DELIVERY,
    required this.DELIVERED,
    required this.FAILED,
  });

  @JsonKey(
    name: r'ALL',
    required: true,
    includeIfNull: false,
  )
  final int ALL;

  @JsonKey(
    name: r'PENDING',
    required: true,
    includeIfNull: false,
  )
  final int PENDING;

  @JsonKey(
    name: r'PREPARING',
    required: true,
    includeIfNull: false,
  )
  final int PREPARING;

  @JsonKey(
    name: r'OUT_FOR_DELIVERY',
    required: true,
    includeIfNull: false,
  )
  final int OUT_FOR_DELIVERY;

  @JsonKey(
    name: r'DELIVERED',
    required: true,
    includeIfNull: false,
  )
  final int DELIVERED;

  @JsonKey(
    name: r'FAILED',
    required: true,
    includeIfNull: false,
  )
  final int FAILED;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryCounts &&
          other.ALL == ALL &&
          other.PENDING == PENDING &&
          other.PREPARING == PREPARING &&
          other.OUT_FOR_DELIVERY == OUT_FOR_DELIVERY &&
          other.DELIVERED == DELIVERED &&
          other.FAILED == FAILED;

  @override
  int get hashCode =>
      ALL.hashCode +
      PENDING.hashCode +
      PREPARING.hashCode +
      OUT_FOR_DELIVERY.hashCode +
      DELIVERED.hashCode +
      FAILED.hashCode;

  factory DeliveryCounts.fromJson(Map<String, dynamic> json) =>
      _$DeliveryCountsFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryCountsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
