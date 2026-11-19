//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'report_sales_bucket.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportSalesBucket {
  /// Returns a new [ReportSalesBucket] instance.
  ReportSalesBucket({
    required this.from,
    required this.to,
    required this.salesPaise,
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
    name: r'salesPaise',
    required: true,
    includeIfNull: false,
  )
  final String salesPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportSalesBucket &&
          other.from == from &&
          other.to == to &&
          other.salesPaise == salesPaise;

  @override
  int get hashCode => from.hashCode + to.hashCode + salesPaise.hashCode;

  factory ReportSalesBucket.fromJson(Map<String, dynamic> json) =>
      _$ReportSalesBucketFromJson(json);

  Map<String, dynamic> toJson() => _$ReportSalesBucketToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
