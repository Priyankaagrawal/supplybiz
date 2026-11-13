//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/order_line_input.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_place_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderPlaceInput {
  /// Returns a new [OrderPlaceInput] instance.
  OrderPlaceInput({
    required this.vendorId,
    required this.addressId,
    required this.deliveryDate,
    required this.timeSlot,
    required this.paymentMode,
    required this.items,
    required this.expectedTotalPaise,
  });

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'addressId',
    required: true,
    includeIfNull: false,
  )
  final String addressId;

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
    name: r'paymentMode',
    required: true,
    includeIfNull: false,
  )
  final OrderPlaceInputPaymentModeEnum paymentMode;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<OrderLineInput> items;

  /// Reviewed quote total, exact integer paise as decimal string.
  @JsonKey(
    name: r'expectedTotalPaise',
    required: true,
    includeIfNull: false,
  )
  final String expectedTotalPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderPlaceInput &&
          other.vendorId == vendorId &&
          other.addressId == addressId &&
          other.deliveryDate == deliveryDate &&
          other.timeSlot == timeSlot &&
          other.paymentMode == paymentMode &&
          other.items == items &&
          other.expectedTotalPaise == expectedTotalPaise;

  @override
  int get hashCode =>
      vendorId.hashCode +
      addressId.hashCode +
      deliveryDate.hashCode +
      timeSlot.hashCode +
      paymentMode.hashCode +
      items.hashCode +
      expectedTotalPaise.hashCode;

  factory OrderPlaceInput.fromJson(Map<String, dynamic> json) =>
      _$OrderPlaceInputFromJson(json);

  Map<String, dynamic> toJson() => _$OrderPlaceInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum OrderPlaceInputPaymentModeEnum {
  @JsonValue(r'POD_CASH')
  POD_CASH(r'POD_CASH'),
  @JsonValue(r'POD_UPI')
  POD_UPI(r'POD_UPI');

  const OrderPlaceInputPaymentModeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
