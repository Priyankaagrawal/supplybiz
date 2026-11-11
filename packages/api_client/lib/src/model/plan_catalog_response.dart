//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/plan_catalog_row.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_catalog_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanCatalogResponse {
  /// Returns a new [PlanCatalogResponse] instance.
  PlanCatalogResponse({
    required this.items,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<PlanCatalogRow> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanCatalogResponse && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory PlanCatalogResponse.fromJson(Map<String, dynamic> json) =>
      _$PlanCatalogResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlanCatalogResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
