//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/inbox_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inbox_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InboxResponse {
  /// Returns a new [InboxResponse] instance.
  InboxResponse({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<InboxItem> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @JsonKey(
    name: r'unreadCount',
    required: true,
    includeIfNull: false,
  )
  final int unreadCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InboxResponse &&
          other.items == items &&
          other.total == total &&
          other.unreadCount == unreadCount;

  @override
  int get hashCode => items.hashCode + total.hashCode + unreadCount.hashCode;

  factory InboxResponse.fromJson(Map<String, dynamic> json) =>
      _$InboxResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InboxResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
