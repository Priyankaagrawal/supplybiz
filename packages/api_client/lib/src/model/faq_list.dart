//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/faq_row.dart';
import 'package:json_annotation/json_annotation.dart';

part 'faq_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FaqList {
  /// Returns a new [FaqList] instance.
  FaqList({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<FaqRow> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaqList && other.items == items && other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory FaqList.fromJson(Map<String, dynamic> json) =>
      _$FaqListFromJson(json);

  Map<String, dynamic> toJson() => _$FaqListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
