//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/vendor_collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_collection_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorCollectionList {
  /// Returns a new [VendorCollectionList] instance.
  VendorCollectionList({
    required this.items,
    required this.total,
    required this.month,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<VendorCollection> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @JsonKey(
    name: r'month',
    required: true,
    includeIfNull: false,
  )
  final String month;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorCollectionList &&
          other.items == items &&
          other.total == total &&
          other.month == month;

  @override
  int get hashCode => items.hashCode + total.hashCode + month.hashCode;

  factory VendorCollectionList.fromJson(Map<String, dynamic> json) =>
      _$VendorCollectionListFromJson(json);

  Map<String, dynamic> toJson() => _$VendorCollectionListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
