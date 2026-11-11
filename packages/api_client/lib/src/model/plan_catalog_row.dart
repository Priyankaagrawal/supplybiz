//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/plan_price_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_catalog_row.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanCatalogRow {
  /// Returns a new [PlanCatalogRow] instance.
  PlanCatalogRow({
    required this.updatedAt,
    required this.id,
    required this.code,
    required this.name,
    required this.customerLimit,
    required this.features,
    required this.isPopular,
    required this.status,
    required this.prices,
  });

  @JsonKey(
    name: r'updatedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'code',
    required: true,
    includeIfNull: false,
  )
  final PlanCatalogRowCodeEnum code;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'customerLimit',
    required: true,
    includeIfNull: false,
  )
  final int customerLimit;

  @JsonKey(
    name: r'features',
    required: true,
    includeIfNull: false,
  )
  final List<String> features;

  @JsonKey(
    name: r'isPopular',
    required: true,
    includeIfNull: false,
  )
  final bool isPopular;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final PlanCatalogRowStatusEnum status;

  @JsonKey(
    name: r'prices',
    required: true,
    includeIfNull: false,
  )
  final List<PlanPriceResponse> prices;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanCatalogRow &&
          other.updatedAt == updatedAt &&
          other.id == id &&
          other.code == code &&
          other.name == name &&
          other.customerLimit == customerLimit &&
          other.features == features &&
          other.isPopular == isPopular &&
          other.status == status &&
          other.prices == prices;

  @override
  int get hashCode =>
      updatedAt.hashCode +
      id.hashCode +
      code.hashCode +
      name.hashCode +
      customerLimit.hashCode +
      features.hashCode +
      isPopular.hashCode +
      status.hashCode +
      prices.hashCode;

  factory PlanCatalogRow.fromJson(Map<String, dynamic> json) =>
      _$PlanCatalogRowFromJson(json);

  Map<String, dynamic> toJson() => _$PlanCatalogRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PlanCatalogRowCodeEnum {
  @JsonValue(r'BASIC')
  BASIC(r'BASIC'),
  @JsonValue(r'STANDARD')
  STANDARD(r'STANDARD'),
  @JsonValue(r'BUSINESS')
  BUSINESS(r'BUSINESS'),
  @JsonValue(r'PREMIUM')
  PREMIUM(r'PREMIUM');

  const PlanCatalogRowCodeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum PlanCatalogRowStatusEnum {
  @JsonValue(r'ACTIVE')
  ACTIVE(r'ACTIVE'),
  @JsonValue(r'INACTIVE')
  INACTIVE(r'INACTIVE');

  const PlanCatalogRowStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
