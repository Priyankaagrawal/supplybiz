//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'order_result.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderResult {
  /// Returns a new [OrderResult] instance.
  OrderResult({
    this.itemSummary,
    required this.id,
    required this.orderNo,
    required this.vendorId,
    required this.status,
    required this.version,
    required this.deliveryDate,
    required this.timeSlot,
    required this.totalPaise,
    required this.paymentMode,
    required this.paymentStatus,
    required this.source_,
    required this.createdAt,
  });

  @JsonKey(
    name: r'itemSummary',
    required: false,
    includeIfNull: false,
  )
  final List<String>? itemSummary;

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'orderNo',
    required: true,
    includeIfNull: false,
  )
  final String orderNo;

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'deliveryDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime deliveryDate;

  @JsonKey(
    name: r'timeSlot',
    required: true,
    includeIfNull: false,
  )
  final String timeSlot;

  @JsonKey(
    name: r'totalPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalPaise;

  @JsonKey(
    name: r'paymentMode',
    required: true,
    includeIfNull: false,
  )
  final String paymentMode;

  @JsonKey(
    name: r'paymentStatus',
    required: true,
    includeIfNull: false,
  )
  final String paymentStatus;

  @JsonKey(
    name: r'source',
    required: true,
    includeIfNull: false,
  )
  final String source_;

  @JsonKey(
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )
  final String createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderResult &&
          other.itemSummary == itemSummary &&
          other.id == id &&
          other.orderNo == orderNo &&
          other.vendorId == vendorId &&
          other.status == status &&
          other.version == version &&
          other.deliveryDate == deliveryDate &&
          other.timeSlot == timeSlot &&
          other.totalPaise == totalPaise &&
          other.paymentMode == paymentMode &&
          other.paymentStatus == paymentStatus &&
          other.source_ == source_ &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      itemSummary.hashCode +
      id.hashCode +
      orderNo.hashCode +
      vendorId.hashCode +
      status.hashCode +
      version.hashCode +
      deliveryDate.hashCode +
      timeSlot.hashCode +
      totalPaise.hashCode +
      paymentMode.hashCode +
      paymentStatus.hashCode +
      source_.hashCode +
      createdAt.hashCode;

  factory OrderResult.fromJson(Map<String, dynamic> json) =>
      _$OrderResultFromJson(json);

  Map<String, dynamic> toJson() => _$OrderResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
