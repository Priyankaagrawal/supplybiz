//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/home_delivery_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'home_delivery.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeDelivery {
  /// Returns a new [HomeDelivery] instance.
  HomeDelivery({
    required this.id,
    required this.orderNo,
    required this.vendorId,
    required this.vendorName,
    required this.source_,
    required this.status,
    required this.deliveryDate,
    required this.timeSlot,
    required this.items,
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
    name: r'vendorName',
    required: true,
    includeIfNull: true,
  )
  final String? vendorName;

  @JsonKey(
    name: r'source',
    required: true,
    includeIfNull: false,
  )
  final HomeDeliverySource_Enum source_;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final HomeDeliveryStatusEnum status;

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
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<HomeDeliveryItem> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeDelivery &&
          other.id == id &&
          other.orderNo == orderNo &&
          other.vendorId == vendorId &&
          other.vendorName == vendorName &&
          other.source_ == source_ &&
          other.status == status &&
          other.deliveryDate == deliveryDate &&
          other.timeSlot == timeSlot &&
          other.items == items;

  @override
  int get hashCode =>
      id.hashCode +
      orderNo.hashCode +
      vendorId.hashCode +
      (vendorName == null ? 0 : vendorName.hashCode) +
      source_.hashCode +
      status.hashCode +
      deliveryDate.hashCode +
      timeSlot.hashCode +
      items.hashCode;

  factory HomeDelivery.fromJson(Map<String, dynamic> json) =>
      _$HomeDeliveryFromJson(json);

  Map<String, dynamic> toJson() => _$HomeDeliveryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HomeDeliverySource_Enum {
  @JsonValue(r'APP')
  APP(r'APP'),
  @JsonValue(r'SUBSCRIPTION')
  SUBSCRIPTION(r'SUBSCRIPTION'),
  @JsonValue(r'VENDOR')
  VENDOR(r'VENDOR');

  const HomeDeliverySource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum HomeDeliveryStatusEnum {
  @JsonValue(r'NEW')
  NEW(r'NEW'),
  @JsonValue(r'ACCEPTED')
  ACCEPTED(r'ACCEPTED'),
  @JsonValue(r'REJECTED')
  REJECTED(r'REJECTED'),
  @JsonValue(r'PREPARING')
  PREPARING(r'PREPARING'),
  @JsonValue(r'OUT_FOR_DELIVERY')
  OUT_FOR_DELIVERY(r'OUT_FOR_DELIVERY'),
  @JsonValue(r'DELIVERED')
  DELIVERED(r'DELIVERED'),
  @JsonValue(r'FAILED')
  FAILED(r'FAILED'),
  @JsonValue(r'CANCELLED')
  CANCELLED(r'CANCELLED');

  const HomeDeliveryStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
