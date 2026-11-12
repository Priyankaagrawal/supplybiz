//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'address_deleted.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddressDeleted {
  /// Returns a new [AddressDeleted] instance.
  AddressDeleted({
    required this.id,
    required this.deleted,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )
  final bool deleted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressDeleted && other.id == id && other.deleted == deleted;

  @override
  int get hashCode => id.hashCode + deleted.hashCode;

  factory AddressDeleted.fromJson(Map<String, dynamic> json) =>
      _$AddressDeletedFromJson(json);

  Map<String, dynamic> toJson() => _$AddressDeletedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
