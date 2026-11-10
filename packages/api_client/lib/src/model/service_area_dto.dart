//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'service_area_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServiceAreaDto {
  /// Returns a new [ServiceAreaDto] instance.
  ServiceAreaDto({
    required this.serviceRadiusKm,
    required this.pincodes,
  });

  /// Null disables radius coverage.
  // minimum: 1
  // maximum: 20
  @JsonKey(
    name: r'serviceRadiusKm',
    required: true,
    includeIfNull: true,
  )
  final int? serviceRadiusKm;

  /// Additional coverage; six-digit Indian pincodes.
  @JsonKey(
    name: r'pincodes',
    required: true,
    includeIfNull: false,
  )
  final List<String> pincodes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAreaDto &&
          other.serviceRadiusKm == serviceRadiusKm &&
          other.pincodes == pincodes;

  @override
  int get hashCode =>
      (serviceRadiusKm == null ? 0 : serviceRadiusKm.hashCode) +
      pincodes.hashCode;

  factory ServiceAreaDto.fromJson(Map<String, dynamic> json) =>
      _$ServiceAreaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceAreaDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
