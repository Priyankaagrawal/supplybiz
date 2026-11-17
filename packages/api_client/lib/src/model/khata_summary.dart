//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/khata_account.dart';
import 'package:json_annotation/json_annotation.dart';

part 'khata_summary.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KhataSummary {
  /// Returns a new [KhataSummary] instance.
  KhataSummary({
    required this.totalReceivablePaise,
    required this.totalPayablePaise,
    required this.netBalancePaise,
    required this.items,
    required this.total,
    required this.serverTime,
    required this.businessDate,
  });

  @JsonKey(
    name: r'totalReceivablePaise',
    required: true,
    includeIfNull: false,
  )
  final String totalReceivablePaise;

  @JsonKey(
    name: r'totalPayablePaise',
    required: true,
    includeIfNull: false,
  )
  final String totalPayablePaise;

  @JsonKey(
    name: r'netBalancePaise',
    required: true,
    includeIfNull: false,
  )
  final String netBalancePaise;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<KhataAccount> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhataSummary &&
          other.totalReceivablePaise == totalReceivablePaise &&
          other.totalPayablePaise == totalPayablePaise &&
          other.netBalancePaise == netBalancePaise &&
          other.items == items &&
          other.total == total &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate;

  @override
  int get hashCode =>
      totalReceivablePaise.hashCode +
      totalPayablePaise.hashCode +
      netBalancePaise.hashCode +
      items.hashCode +
      total.hashCode +
      serverTime.hashCode +
      businessDate.hashCode;

  factory KhataSummary.fromJson(Map<String, dynamic> json) =>
      _$KhataSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$KhataSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
