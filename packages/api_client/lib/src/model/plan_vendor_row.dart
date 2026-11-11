//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'plan_vendor_row.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanVendorRow {
  /// Returns a new [PlanVendorRow] instance.
  PlanVendorRow({
    required this.id,
    required this.businessName,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'businessName',
    required: true,
    includeIfNull: true,
  )
  final String? businessName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanVendorRow &&
          other.id == id &&
          other.businessName == businessName;

  @override
  int get hashCode =>
      id.hashCode + (businessName == null ? 0 : businessName.hashCode);

  factory PlanVendorRow.fromJson(Map<String, dynamic> json) =>
      _$PlanVendorRowFromJson(json);

  Map<String, dynamic> toJson() => _$PlanVendorRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
