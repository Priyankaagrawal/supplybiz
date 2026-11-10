//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'product_deleted.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProductDeleted {
  /// Returns a new [ProductDeleted] instance.
  ProductDeleted({
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
      other is ProductDeleted && other.id == id && other.deleted == deleted;

  @override
  int get hashCode => id.hashCode + deleted.hashCode;

  factory ProductDeleted.fromJson(Map<String, dynamic> json) =>
      _$ProductDeletedFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDeletedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
