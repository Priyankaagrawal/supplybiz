//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/discovered_vendor.dart';
import 'package:json_annotation/json_annotation.dart';

part 'discovery_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DiscoveryPage {
  /// Returns a new [DiscoveryPage] instance.
  DiscoveryPage({
    required this.items,
    required this.nextCursor,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<DiscoveredVendor> items;

  @JsonKey(
    name: r'nextCursor',
    required: true,
    includeIfNull: true,
  )
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory DiscoveryPage.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryPageFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoveryPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
