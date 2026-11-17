//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/sale_item_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sale_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaleResponse {
  /// Returns a new [SaleResponse] instance.
  SaleResponse({
    required this.id,
    required this.saleNo,
    required this.vendorCustomerId,
    required this.totalPaise,
    required this.paidPaise,
    required this.balancePaise,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.businessDate,
    required this.createdAt,
    required this.clientCreatedAt,
    required this.items,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'saleNo',
    required: true,
    includeIfNull: false,
  )
  final String saleNo;

  @JsonKey(
    name: r'vendorCustomerId',
    required: true,
    includeIfNull: true,
  )
  final String? vendorCustomerId;

  @JsonKey(
    name: r'totalPaise',
    required: true,
    includeIfNull: false,
  )
  final String totalPaise;

  @JsonKey(
    name: r'paidPaise',
    required: true,
    includeIfNull: false,
  )
  final String paidPaise;

  @JsonKey(
    name: r'balancePaise',
    required: true,
    includeIfNull: false,
  )
  final String balancePaise;

  @JsonKey(
    name: r'paymentStatus',
    required: true,
    includeIfNull: false,
  )
  final SaleResponsePaymentStatusEnum paymentStatus;

  @JsonKey(
    name: r'paymentMethod',
    required: true,
    includeIfNull: false,
  )
  final SaleResponsePaymentMethodEnum paymentMethod;

  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  @JsonKey(
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime createdAt;

  @JsonKey(
    name: r'clientCreatedAt',
    required: true,
    includeIfNull: true,
  )
  final DateTime? clientCreatedAt;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<SaleItemResponse> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleResponse &&
          other.id == id &&
          other.saleNo == saleNo &&
          other.vendorCustomerId == vendorCustomerId &&
          other.totalPaise == totalPaise &&
          other.paidPaise == paidPaise &&
          other.balancePaise == balancePaise &&
          other.paymentStatus == paymentStatus &&
          other.paymentMethod == paymentMethod &&
          other.businessDate == businessDate &&
          other.createdAt == createdAt &&
          other.clientCreatedAt == clientCreatedAt &&
          other.items == items;

  @override
  int get hashCode =>
      id.hashCode +
      saleNo.hashCode +
      (vendorCustomerId == null ? 0 : vendorCustomerId.hashCode) +
      totalPaise.hashCode +
      paidPaise.hashCode +
      balancePaise.hashCode +
      paymentStatus.hashCode +
      paymentMethod.hashCode +
      businessDate.hashCode +
      createdAt.hashCode +
      (clientCreatedAt == null ? 0 : clientCreatedAt.hashCode) +
      items.hashCode;

  factory SaleResponse.fromJson(Map<String, dynamic> json) =>
      _$SaleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SaleResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SaleResponsePaymentStatusEnum {
  @JsonValue(r'PAID')
  PAID(r'PAID'),
  @JsonValue(r'UNPAID')
  UNPAID(r'UNPAID');

  const SaleResponsePaymentStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum SaleResponsePaymentMethodEnum {
  @JsonValue(r'CASH')
  CASH(r'CASH'),
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'OTHER')
  OTHER(r'OTHER');

  const SaleResponsePaymentMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
