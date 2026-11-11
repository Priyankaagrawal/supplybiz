//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/catalog_price_input.dart';
import 'package:json_annotation/json_annotation.dart';

part 'catalog_plan_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CatalogPlanInput {
  /// Returns a new [CatalogPlanInput] instance.
  CatalogPlanInput({
    required this.name,
    required this.status,
    required this.isPopular,
    required this.expectedUpdatedAt,
    required this.reason,
    required this.prices,
  });

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final CatalogPlanInputStatusEnum status;

  @JsonKey(
    name: r'isPopular',
    required: true,
    includeIfNull: false,
  )
  final bool isPopular;

  @JsonKey(
    name: r'expectedUpdatedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime expectedUpdatedAt;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @JsonKey(
    name: r'prices',
    required: true,
    includeIfNull: false,
  )
  final List<CatalogPriceInput> prices;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogPlanInput &&
          other.name == name &&
          other.status == status &&
          other.isPopular == isPopular &&
          other.expectedUpdatedAt == expectedUpdatedAt &&
          other.reason == reason &&
          other.prices == prices;

  @override
  int get hashCode =>
      name.hashCode +
      status.hashCode +
      isPopular.hashCode +
      expectedUpdatedAt.hashCode +
      reason.hashCode +
      prices.hashCode;

  factory CatalogPlanInput.fromJson(Map<String, dynamic> json) =>
      _$CatalogPlanInputFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogPlanInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CatalogPlanInputStatusEnum {
  @JsonValue(r'ACTIVE')
  ACTIVE(r'ACTIVE'),
  @JsonValue(r'INACTIVE')
  INACTIVE(r'INACTIVE');

  const CatalogPlanInputStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
