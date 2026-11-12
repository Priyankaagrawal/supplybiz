//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'address_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddressResponse {
  /// Returns a new [AddressResponse] instance.
  AddressResponse({
    required this.label,
    required this.line1,
    required this.line2,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.id,
  });

  @JsonKey(
    name: r'label',
    required: true,
    includeIfNull: false,
  )
  final String label;

  /// House or flat.
  @JsonKey(
    name: r'line1',
    required: true,
    includeIfNull: false,
  )
  final String line1;

  /// Street or area.
  @JsonKey(
    name: r'line2',
    required: true,
    includeIfNull: false,
  )
  final String line2;

  @JsonKey(
    name: r'landmark',
    required: true,
    includeIfNull: false,
  )
  final String landmark;

  @JsonKey(
    name: r'city',
    required: true,
    includeIfNull: false,
  )
  final String city;

  @JsonKey(
    name: r'state',
    required: true,
    includeIfNull: false,
  )
  final String state;

  @JsonKey(
    name: r'pincode',
    required: true,
    includeIfNull: false,
  )
  final String pincode;

  // minimum: -90
  // maximum: 90
  @JsonKey(
    name: r'latitude',
    required: true,
    includeIfNull: false,
  )
  final num latitude;

  // minimum: -180
  // maximum: 180
  @JsonKey(
    name: r'longitude',
    required: true,
    includeIfNull: false,
  )
  final num longitude;

  /// First address is always default. Use true to move the default.
  @JsonKey(
    name: r'isDefault',
    required: true,
    includeIfNull: false,
  )
  final bool isDefault;

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressResponse &&
          other.label == label &&
          other.line1 == line1 &&
          other.line2 == line2 &&
          other.landmark == landmark &&
          other.city == city &&
          other.state == state &&
          other.pincode == pincode &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.isDefault == isDefault &&
          other.id == id;

  @override
  int get hashCode =>
      label.hashCode +
      line1.hashCode +
      line2.hashCode +
      landmark.hashCode +
      city.hashCode +
      state.hashCode +
      pincode.hashCode +
      latitude.hashCode +
      longitude.hashCode +
      isDefault.hashCode +
      id.hashCode;

  factory AddressResponse.fromJson(Map<String, dynamic> json) =>
      _$AddressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddressResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
