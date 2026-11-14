//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/payment_record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentList {
  /// Returns a new [PaymentList] instance.
  PaymentList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<PaymentRecord> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentList && other.items == items && other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory PaymentList.fromJson(Map<String, dynamic> json) =>
      _$PaymentListFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
