//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'plan_price_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanPriceResponse {
  /// Returns a new [PlanPriceResponse] instance.
  PlanPriceResponse({
    required this.duration,
    required this.pricePaise,
  });

  @JsonKey(
    name: r'duration',
    required: true,
    includeIfNull: false,
  )
  final PlanPriceResponseDurationEnum duration;

  // minimum: 0
  @JsonKey(
    name: r'pricePaise',
    required: true,
    includeIfNull: false,
  )
  final int pricePaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanPriceResponse &&
          other.duration == duration &&
          other.pricePaise == pricePaise;

  @override
  int get hashCode => duration.hashCode + pricePaise.hashCode;

  factory PlanPriceResponse.fromJson(Map<String, dynamic> json) =>
      _$PlanPriceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlanPriceResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PlanPriceResponseDurationEnum {
  @JsonValue(r'MONTHLY')
  MONTHLY(r'MONTHLY'),
  @JsonValue(r'HALF_YEARLY')
  HALF_YEARLY(r'HALF_YEARLY'),
  @JsonValue(r'YEARLY')
  YEARLY(r'YEARLY');

  const PlanPriceResponseDurationEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
