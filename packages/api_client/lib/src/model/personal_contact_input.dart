//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'personal_contact_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalContactInput {
  /// Returns a new [PersonalContactInput] instance.
  PersonalContactInput({
    required this.name,
    this.mobile,
  });

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'mobile',
    required: false,
    includeIfNull: false,
  )
  final String? mobile;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalContactInput &&
          other.name == name &&
          other.mobile == mobile;

  @override
  int get hashCode => name.hashCode + (mobile == null ? 0 : mobile.hashCode);

  factory PersonalContactInput.fromJson(Map<String, dynamic> json) =>
      _$PersonalContactInputFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalContactInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
