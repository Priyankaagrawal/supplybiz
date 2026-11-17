//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'personal_contact_record.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalContactRecord {
  /// Returns a new [PersonalContactRecord] instance.
  PersonalContactRecord({
    required this.id,
    required this.version,
    required this.name,
    required this.mobile,
    required this.balancePaise,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'mobile',
    required: true,
    includeIfNull: true,
  )
  final String? mobile;

  @JsonKey(
    name: r'balancePaise',
    required: true,
    includeIfNull: false,
  )
  final String balancePaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalContactRecord &&
          other.id == id &&
          other.version == version &&
          other.name == name &&
          other.mobile == mobile &&
          other.balancePaise == balancePaise;

  @override
  int get hashCode =>
      id.hashCode +
      version.hashCode +
      name.hashCode +
      (mobile == null ? 0 : mobile.hashCode) +
      balancePaise.hashCode;

  factory PersonalContactRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalContactRecordFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalContactRecordToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
