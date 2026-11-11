//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/link_request_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'link_request_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LinkRequestList {
  /// Returns a new [LinkRequestList] instance.
  LinkRequestList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<LinkRequestResponse> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkRequestList && other.items == items && other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory LinkRequestList.fromJson(Map<String, dynamic> json) =>
      _$LinkRequestListFromJson(json);

  Map<String, dynamic> toJson() => _$LinkRequestListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
