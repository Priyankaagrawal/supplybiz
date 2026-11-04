//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/audit_row.dart';
import 'package:json_annotation/json_annotation.dart';

part 'audit_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuditPage {
  /// Returns a new [AuditPage] instance.
  AuditPage({
    required this.items,
    required this.hasMore,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<AuditRow> items;

  @JsonKey(
    name: r'hasMore',
    required: true,
    includeIfNull: false,
  )
  final bool hasMore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditPage && other.items == items && other.hasMore == hasMore;

  @override
  int get hashCode => items.hashCode + hasMore.hashCode;

  factory AuditPage.fromJson(Map<String, dynamic> json) =>
      _$AuditPageFromJson(json);

  Map<String, dynamic> toJson() => _$AuditPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
