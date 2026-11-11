//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'read_notifications.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReadNotifications {
  /// Returns a new [ReadNotifications] instance.
  ReadNotifications({
    this.role,
    this.ids,
    this.all,
  });

  @JsonKey(
    name: r'role',
    required: false,
    includeIfNull: false,
  )
  final ReadNotificationsRoleEnum? role;

  /// Provide IDs or all=true, exclusively.
  @JsonKey(
    name: r'ids',
    required: false,
    includeIfNull: false,
  )
  final List<String>? ids;

  @JsonKey(
    name: r'all',
    required: false,
    includeIfNull: false,
  )
  final bool? all;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadNotifications &&
          other.role == role &&
          other.ids == ids &&
          other.all == all;

  @override
  int get hashCode => role.hashCode + ids.hashCode + all.hashCode;

  factory ReadNotifications.fromJson(Map<String, dynamic> json) =>
      _$ReadNotificationsFromJson(json);

  Map<String, dynamic> toJson() => _$ReadNotificationsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ReadNotificationsRoleEnum {
  @JsonValue(r'VENDOR')
  VENDOR(r'VENDOR'),
  @JsonValue(r'CUSTOMER')
  CUSTOMER(r'CUSTOMER');

  const ReadNotificationsRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
