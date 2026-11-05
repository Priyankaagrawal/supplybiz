//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/kyc_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'kyc_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KycPage {
  /// Returns a new [KycPage] instance.
  KycPage({
    required this.items,
    required this.hasMore,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<KycResponse> items;

  @JsonKey(
    name: r'hasMore',
    required: true,
    includeIfNull: false,
  )
  final bool hasMore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KycPage && other.items == items && other.hasMore == hasMore;

  @override
  int get hashCode => items.hashCode + hasMore.hashCode;

  factory KycPage.fromJson(Map<String, dynamic> json) =>
      _$KycPageFromJson(json);

  Map<String, dynamic> toJson() => _$KycPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
