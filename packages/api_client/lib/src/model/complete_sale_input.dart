//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/sale_line_input.dart';
import 'package:json_annotation/json_annotation.dart';

part 'complete_sale_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CompleteSaleInput {
  /// Returns a new [CompleteSaleInput] instance.
  CompleteSaleInput({
    this.vendorCustomerId,
    required this.items,
    required this.paidPaise,
    required this.paymentMethod,
    this.clientCreatedAt,
  });

  /// Omitted for anonymous walk-in; no synthetic customer is created.
  @JsonKey(
    name: r'vendorCustomerId',
    required: false,
    includeIfNull: false,
  )
  final String? vendorCustomerId;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<SaleLineInput> items;

  /// Recorded external payment, 0 through server total. Walk-in must equal total.
  @JsonKey(
    name: r'paidPaise',
    required: true,
    includeIfNull: false,
  )
  final String paidPaise;

  @JsonKey(
    name: r'paymentMethod',
    required: true,
    includeIfNull: false,
  )
  final CompleteSaleInputPaymentMethodEnum paymentMethod;

  /// Untrusted offline audit metadata only; never controls business date, authorization or posting.
  @JsonKey(
    name: r'clientCreatedAt',
    required: false,
    includeIfNull: false,
  )
  final DateTime? clientCreatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompleteSaleInput &&
          other.vendorCustomerId == vendorCustomerId &&
          other.items == items &&
          other.paidPaise == paidPaise &&
          other.paymentMethod == paymentMethod &&
          other.clientCreatedAt == clientCreatedAt;

  @override
  int get hashCode =>
      vendorCustomerId.hashCode +
      items.hashCode +
      paidPaise.hashCode +
      paymentMethod.hashCode +
      clientCreatedAt.hashCode;

  factory CompleteSaleInput.fromJson(Map<String, dynamic> json) =>
      _$CompleteSaleInputFromJson(json);

  Map<String, dynamic> toJson() => _$CompleteSaleInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CompleteSaleInputPaymentMethodEnum {
  @JsonValue(r'CASH')
  CASH(r'CASH'),
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'OTHER')
  OTHER(r'OTHER');

  const CompleteSaleInputPaymentMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
