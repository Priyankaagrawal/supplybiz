//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'inbox_item.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InboxItem {
  /// Returns a new [InboxItem] instance.
  InboxItem({
    required this.id,
    required this.role,
    required this.category,
    required this.type,
    required this.title,
    required this.body,
    required this.path,
    required this.readAt,
    required this.createdAt,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'role',
    required: true,
    includeIfNull: false,
  )
  final InboxItemRoleEnum role;

  @JsonKey(
    name: r'category',
    required: true,
    includeIfNull: false,
  )
  final InboxItemCategoryEnum category;

  @JsonKey(
    name: r'type',
    required: true,
    includeIfNull: false,
  )
  final String type;

  @JsonKey(
    name: r'title',
    required: true,
    includeIfNull: false,
  )
  final String title;

  @JsonKey(
    name: r'body',
    required: true,
    includeIfNull: false,
  )
  final String body;

  @JsonKey(
    name: r'path',
    required: true,
    includeIfNull: false,
  )
  final String path;

  @JsonKey(
    name: r'readAt',
    required: true,
    includeIfNull: true,
  )
  final DateTime? readAt;

  @JsonKey(
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InboxItem &&
          other.id == id &&
          other.role == role &&
          other.category == category &&
          other.type == type &&
          other.title == title &&
          other.body == body &&
          other.path == path &&
          other.readAt == readAt &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      role.hashCode +
      category.hashCode +
      type.hashCode +
      title.hashCode +
      body.hashCode +
      path.hashCode +
      (readAt == null ? 0 : readAt.hashCode) +
      createdAt.hashCode;

  factory InboxItem.fromJson(Map<String, dynamic> json) =>
      _$InboxItemFromJson(json);

  Map<String, dynamic> toJson() => _$InboxItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum InboxItemRoleEnum {
  @JsonValue(r'VENDOR')
  VENDOR(r'VENDOR'),
  @JsonValue(r'CUSTOMER')
  CUSTOMER(r'CUSTOMER');

  const InboxItemRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum InboxItemCategoryEnum {
  @JsonValue(r'ORDERS')
  ORDERS(r'ORDERS'),
  @JsonValue(r'PAYMENTS')
  PAYMENTS(r'PAYMENTS'),
  @JsonValue(r'DELIVERY')
  DELIVERY(r'DELIVERY'),
  @JsonValue(r'SYSTEM')
  SYSTEM(r'SYSTEM');

  const InboxItemCategoryEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
