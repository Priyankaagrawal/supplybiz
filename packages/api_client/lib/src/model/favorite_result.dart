//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'favorite_result.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FavoriteResult {
  /// Returns a new [FavoriteResult] instance.
  FavoriteResult({
    required this.vendorId,
    required this.favorite,
  });

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'favorite',
    required: true,
    includeIfNull: false,
  )
  final bool favorite;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteResult &&
          other.vendorId == vendorId &&
          other.favorite == favorite;

  @override
  int get hashCode => vendorId.hashCode + favorite.hashCode;

  factory FavoriteResult.fromJson(Map<String, dynamic> json) =>
      _$FavoriteResultFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
