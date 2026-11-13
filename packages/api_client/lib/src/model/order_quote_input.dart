//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/order_line_input.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_quote_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderQuoteInput {
  /// Returns a new [OrderQuoteInput] instance.
  OrderQuoteInput({
    required this.vendorId,
    required this.addressId,
    required this.deliveryDate,
    required this.timeSlot,
    required this.paymentMode,
    required this.items,
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
  final OrderQuoteInputPaymentModeEnum paymentMode;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<OrderLineInput> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderQuoteInput &&
          other.vendorId == vendorId &&
          other.addressId == addressId &&
          other.deliveryDate == deliveryDate &&
          other.timeSlot == timeSlot &&
          other.paymentMode == paymentMode &&
          other.items == items;

  @override
  int get hashCode =>
      vendorId.hashCode +
      addressId.hashCode +
      deliveryDate.hashCode +
      timeSlot.hashCode +
      paymentMode.hashCode +
      items.hashCode;

  factory OrderQuoteInput.fromJson(Map<String, dynamic> json) =>
      _$OrderQuoteInputFromJson(json);

  Map<String, dynamic> toJson() => _$OrderQuoteInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum OrderQuoteInputPaymentModeEnum {
  @JsonValue(r'POD_CASH')
  POD_CASH(r'POD_CASH'),
  @JsonValue(r'POD_UPI')
  POD_UPI(r'POD_UPI');

  const OrderQuoteInputPaymentModeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
