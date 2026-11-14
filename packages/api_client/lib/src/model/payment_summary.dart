//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'payment_summary.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentSummary {
  /// Returns a new [PaymentSummary] instance.
  PaymentSummary({
    required this.serverTime,
    required this.businessDate,
    required this.totalReceivablePaise,
    required this.thisMonthReceivedPaise,
  });

  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final String serverTime;

  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  /// Sum of positive customer dues; advances do not offset other customers.
  @JsonKey(
    name: r'totalReceivablePaise',
    required: true,
    includeIfNull: false,
  )
  final String totalReceivablePaise;

  /// All owned receipts with receivedOn in the current server IST month.
  @JsonKey(
    name: r'thisMonthReceivedPaise',
    required: true,
    includeIfNull: false,
  )
  final String thisMonthReceivedPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentSummary &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.totalReceivablePaise == totalReceivablePaise &&
          other.thisMonthReceivedPaise == thisMonthReceivedPaise;

  @override
  int get hashCode =>
      serverTime.hashCode +
      businessDate.hashCode +
      totalReceivablePaise.hashCode +
      thisMonthReceivedPaise.hashCode;

  factory PaymentSummary.fromJson(Map<String, dynamic> json) =>
      _$PaymentSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
