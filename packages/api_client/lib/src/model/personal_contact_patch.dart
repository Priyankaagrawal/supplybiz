//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'personal_contact_patch.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalContactPatch {
  /// Returns a new [PersonalContactPatch] instance.
  PersonalContactPatch({
    required this.version,
    this.name,
    this.mobile,
    this.clearMobile,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'name',
    required: false,
    includeIfNull: false,
  )
  final String? name;

  @JsonKey(
    name: r'mobile',
    required: false,
    includeIfNull: false,
  )
  final String? mobile;

  /// True clears mobile for typed clients; cannot accompany a non-null value.
  @JsonKey(
    name: r'clearMobile',
    required: false,
    includeIfNull: false,
  )
  final bool? clearMobile;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalContactPatch &&
          other.version == version &&
          other.name == name &&
          other.mobile == mobile &&
          other.clearMobile == clearMobile;

  @override
  int get hashCode =>
      version.hashCode +
      name.hashCode +
      (mobile == null ? 0 : mobile.hashCode) +
      clearMobile.hashCode;

  factory PersonalContactPatch.fromJson(Map<String, dynamic> json) =>
      _$PersonalContactPatchFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalContactPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
