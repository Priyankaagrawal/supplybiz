//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/payment_claim_record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment_claim_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentClaimList {
  /// Returns a new [PaymentClaimList] instance.
  PaymentClaimList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<PaymentClaimRecord> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentClaimList && other.items == items && other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory PaymentClaimList.fromJson(Map<String, dynamic> json) =>
      _$PaymentClaimListFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentClaimListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
