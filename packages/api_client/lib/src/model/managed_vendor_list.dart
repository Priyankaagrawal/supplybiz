//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/managed_vendor.dart';
import 'package:json_annotation/json_annotation.dart';

part 'managed_vendor_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedVendorList {
  /// Returns a new [ManagedVendorList] instance.
  ManagedVendorList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<ManagedVendor> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedVendorList &&
          other.items == items &&
          other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory ManagedVendorList.fromJson(Map<String, dynamic> json) =>
      _$ManagedVendorListFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedVendorListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
