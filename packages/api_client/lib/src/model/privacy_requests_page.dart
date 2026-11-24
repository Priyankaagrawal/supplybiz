//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/privacy_request_row.dart';
import 'package:json_annotation/json_annotation.dart';

part 'privacy_requests_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PrivacyRequestsPage {
  /// Returns a new [PrivacyRequestsPage] instance.
  PrivacyRequestsPage({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<PrivacyRequestRow> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final num total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacyRequestsPage &&
          other.items == items &&
          other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory PrivacyRequestsPage.fromJson(Map<String, dynamic> json) =>
      _$PrivacyRequestsPageFromJson(json);

  Map<String, dynamic> toJson() => _$PrivacyRequestsPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
