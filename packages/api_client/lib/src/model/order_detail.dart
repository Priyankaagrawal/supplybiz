//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/order_status_event.dart';
import 'package:supplybiz_api_client/src/model/address_response.dart';
import 'package:supplybiz_api_client/src/model/order_priced_line.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_detail.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderDetail {
  /// Returns a new [OrderDetail] instance.
  OrderDetail({
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
    required this.vendorName,
    required this.customerName,
    required this.customerMobile,
    required this.address,
    required this.items,
    required this.timeline,
    required this.subtotalPaise,
    required this.deliveryChargePaise,
    required this.discountPaise,
    required this.rejectReason,
    required this.cancelReason,
    required this.failReason,
  });

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

  @JsonKey(
    name: r'vendorName',
    required: true,
    includeIfNull: true,
  )
  final String? vendorName;

  @JsonKey(
    name: r'customerName',
    required: true,
    includeIfNull: false,
  )
  final String customerName;

  @JsonKey(
    name: r'customerMobile',
    required: true,
    includeIfNull: false,
  )
  final String customerMobile;

  @JsonKey(
    name: r'address',
    required: true,
    includeIfNull: false,
  )
  final AddressResponse address;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<OrderPricedLine> items;

  @JsonKey(
    name: r'timeline',
    required: true,
    includeIfNull: false,
  )
  final List<OrderStatusEvent> timeline;

  @JsonKey(
    name: r'subtotalPaise',
    required: true,
    includeIfNull: false,
  )
  final String subtotalPaise;

  @JsonKey(
    name: r'deliveryChargePaise',
    required: true,
    includeIfNull: false,
  )
  final String deliveryChargePaise;

  @JsonKey(
    name: r'discountPaise',
    required: true,
    includeIfNull: false,
  )
  final String discountPaise;

  @JsonKey(
    name: r'rejectReason',
    required: true,
    includeIfNull: true,
  )
  final String? rejectReason;

  @JsonKey(
    name: r'cancelReason',
    required: true,
    includeIfNull: true,
  )
  final String? cancelReason;

  @JsonKey(
    name: r'failReason',
    required: true,
    includeIfNull: true,
  )
  final String? failReason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderDetail &&
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
          other.createdAt == createdAt &&
          other.vendorName == vendorName &&
          other.customerName == customerName &&
          other.customerMobile == customerMobile &&
          other.address == address &&
          other.items == items &&
          other.timeline == timeline &&
          other.subtotalPaise == subtotalPaise &&
          other.deliveryChargePaise == deliveryChargePaise &&
          other.discountPaise == discountPaise &&
          other.rejectReason == rejectReason &&
          other.cancelReason == cancelReason &&
          other.failReason == failReason;

  @override
  int get hashCode =>
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
      createdAt.hashCode +
      (vendorName == null ? 0 : vendorName.hashCode) +
      customerName.hashCode +
      customerMobile.hashCode +
      address.hashCode +
      items.hashCode +
      timeline.hashCode +
      subtotalPaise.hashCode +
      deliveryChargePaise.hashCode +
      discountPaise.hashCode +
      (rejectReason == null ? 0 : rejectReason.hashCode) +
      (cancelReason == null ? 0 : cancelReason.hashCode) +
      (failReason == null ? 0 : failReason.hashCode);

  factory OrderDetail.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
