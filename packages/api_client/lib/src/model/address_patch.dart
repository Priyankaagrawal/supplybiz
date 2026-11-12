//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'address_patch.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddressPatch {
  /// Returns a new [AddressPatch] instance.
  AddressPatch({
    this.label,
    this.line1,
    this.line2,
    this.landmark,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.isDefault,
  });

  @JsonKey(
    name: r'label',
    required: false,
    includeIfNull: false,
  )
  final String? label;

  /// House or flat.
  @JsonKey(
    name: r'line1',
    required: false,
    includeIfNull: false,
  )
  final String? line1;

  /// Street or area.
  @JsonKey(
    name: r'line2',
    required: false,
    includeIfNull: false,
  )
  final String? line2;

  @JsonKey(
    name: r'landmark',
    required: false,
    includeIfNull: false,
  )
  final String? landmark;

  @JsonKey(
    name: r'city',
    required: false,
    includeIfNull: false,
  )
  final String? city;

  @JsonKey(
    name: r'state',
    required: false,
    includeIfNull: false,
  )
  final String? state;

  @JsonKey(
    name: r'pincode',
    required: false,
    includeIfNull: false,
  )
  final String? pincode;

  // minimum: -90
  // maximum: 90
  @JsonKey(
    name: r'latitude',
    required: false,
    includeIfNull: false,
  )
  final num? latitude;

  // minimum: -180
  // maximum: 180
  @JsonKey(
    name: r'longitude',
    required: false,
    includeIfNull: false,
  )
  final num? longitude;

  /// First address is always default. Use true to move the default.
  @JsonKey(
    name: r'isDefault',
    required: false,
    includeIfNull: false,
  )
  final bool? isDefault;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressPatch &&
          other.label == label &&
          other.line1 == line1 &&
          other.line2 == line2 &&
          other.landmark == landmark &&
          other.city == city &&
          other.state == state &&
          other.pincode == pincode &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.isDefault == isDefault;

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
      isDefault.hashCode;

  factory AddressPatch.fromJson(Map<String, dynamic> json) =>
      _$AddressPatchFromJson(json);

  Map<String, dynamic> toJson() => _$AddressPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
