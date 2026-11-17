//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/personal_entry_record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'personal_entry_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalEntryList {
  /// Returns a new [PersonalEntryList] instance.
  PersonalEntryList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<PersonalEntryRecord> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalEntryList &&
          other.items == items &&
          other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory PersonalEntryList.fromJson(Map<String, dynamic> json) =>
      _$PersonalEntryListFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalEntryListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
