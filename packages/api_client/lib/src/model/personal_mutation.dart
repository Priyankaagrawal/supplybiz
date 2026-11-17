//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'personal_mutation.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalMutation {
  /// Returns a new [PersonalMutation] instance.
  PersonalMutation({
    required this.id,
    required this.version,
    required this.deleted,
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
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )
  final bool deleted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalMutation &&
          other.id == id &&
          other.version == version &&
          other.deleted == deleted;

  @override
  int get hashCode => id.hashCode + version.hashCode + deleted.hashCode;

  factory PersonalMutation.fromJson(Map<String, dynamic> json) =>
      _$PersonalMutationFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalMutationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
