//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/legal_row.dart';
import 'package:json_annotation/json_annotation.dart';

part 'legal_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LegalList {
  /// Returns a new [LegalList] instance.
  LegalList({
    required this.items,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<LegalRow> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LegalList && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory LegalList.fromJson(Map<String, dynamic> json) =>
      _$LegalListFromJson(json);

  Map<String, dynamic> toJson() => _$LegalListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
