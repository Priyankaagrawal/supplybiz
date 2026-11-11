//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'catalog_price_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CatalogPriceInput {
  /// Returns a new [CatalogPriceInput] instance.
  CatalogPriceInput({
    required this.duration,
    required this.pricePaise,
  });

  @JsonKey(
    name: r'duration',
    required: true,
    includeIfNull: false,
  )
  final CatalogPriceInputDurationEnum duration;

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(
    name: r'pricePaise',
    required: true,
    includeIfNull: false,
  )
  final int pricePaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogPriceInput &&
          other.duration == duration &&
          other.pricePaise == pricePaise;

  @override
  int get hashCode => duration.hashCode + pricePaise.hashCode;

  factory CatalogPriceInput.fromJson(Map<String, dynamic> json) =>
      _$CatalogPriceInputFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogPriceInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CatalogPriceInputDurationEnum {
  @JsonValue(r'MONTHLY')
  MONTHLY(r'MONTHLY'),
  @JsonValue(r'HALF_YEARLY')
  HALF_YEARLY(r'HALF_YEARLY'),
  @JsonValue(r'YEARLY')
  YEARLY(r'YEARLY');

  const CatalogPriceInputDurationEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
