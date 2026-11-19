//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/report_sales_bucket.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_daily_sales.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportDailySales {
  /// Returns a new [ReportDailySales] instance.
  ReportDailySales({
    required this.from,
    required this.to,
    required this.serverTime,
    required this.businessDate,
    required this.bucket,
    required this.items,
  });

  @JsonKey(
    name: r'from',
    required: true,
    includeIfNull: false,
  )
  final DateTime from;

  @JsonKey(
    name: r'to',
    required: true,
    includeIfNull: false,
  )
  final DateTime to;

  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final DateTime serverTime;

  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  /// DAY through 62 inclusive days; otherwise Monday-based weeks clipped to requested range. Zero periods included.
  @JsonKey(
    name: r'bucket',
    required: true,
    includeIfNull: false,
  )
  final ReportDailySalesBucketEnum bucket;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<ReportSalesBucket> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportDailySales &&
          other.from == from &&
          other.to == to &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.bucket == bucket &&
          other.items == items;

  @override
  int get hashCode =>
      from.hashCode +
      to.hashCode +
      serverTime.hashCode +
      businessDate.hashCode +
      bucket.hashCode +
      items.hashCode;

  factory ReportDailySales.fromJson(Map<String, dynamic> json) =>
      _$ReportDailySalesFromJson(json);

  Map<String, dynamic> toJson() => _$ReportDailySalesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// DAY through 62 inclusive days; otherwise Monday-based weeks clipped to requested range. Zero periods included.
enum ReportDailySalesBucketEnum {
  @JsonValue(r'DAY')
  DAY(r'DAY'),
  @JsonValue(r'WEEK')
  WEEK(r'WEEK');

  const ReportDailySalesBucketEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
