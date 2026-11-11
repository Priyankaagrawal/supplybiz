//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/plan_vendor_row.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_vendor_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanVendorList {
  /// Returns a new [PlanVendorList] instance.
  PlanVendorList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<PlanVendorRow> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanVendorList && other.items == items && other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory PlanVendorList.fromJson(Map<String, dynamic> json) =>
      _$PlanVendorListFromJson(json);

  Map<String, dynamic> toJson() => _$PlanVendorListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
