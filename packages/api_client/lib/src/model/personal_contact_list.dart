//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/personal_contact_record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'personal_contact_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalContactList {
  /// Returns a new [PersonalContactList] instance.
  PersonalContactList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<PersonalContactRecord> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalContactList &&
          other.items == items &&
          other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory PersonalContactList.fromJson(Map<String, dynamic> json) =>
      _$PersonalContactListFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalContactListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
