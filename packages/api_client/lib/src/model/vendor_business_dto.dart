//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_business_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorBusinessDto {
  /// Returns a new [VendorBusinessDto] instance.
  VendorBusinessDto({
    required this.businessName,
    this.gstin,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.shopPhotoMediaId,
  });

  @JsonKey(
    name: r'businessName',
    required: true,
    includeIfNull: false,
  )
  final String businessName;

  @JsonKey(
    name: r'gstin',
    required: false,
    includeIfNull: false,
  )
  final String? gstin;

  @JsonKey(
    name: r'addressLine',
    required: true,
    includeIfNull: false,
  )
  final String addressLine;

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

  @JsonKey(
    name: r'shopPhotoMediaId',
    required: false,
    includeIfNull: false,
  )
  final String? shopPhotoMediaId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorBusinessDto &&
          other.businessName == businessName &&
          other.gstin == gstin &&
          other.addressLine == addressLine &&
          other.city == city &&
          other.state == state &&
          other.pincode == pincode &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.shopPhotoMediaId == shopPhotoMediaId;

  @override
  int get hashCode =>
      businessName.hashCode +
      (gstin == null ? 0 : gstin.hashCode) +
      addressLine.hashCode +
      city.hashCode +
      state.hashCode +
      pincode.hashCode +
      latitude.hashCode +
      longitude.hashCode +
      (shopPhotoMediaId == null ? 0 : shopPhotoMediaId.hashCode);

  factory VendorBusinessDto.fromJson(Map<String, dynamic> json) =>
      _$VendorBusinessDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VendorBusinessDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
