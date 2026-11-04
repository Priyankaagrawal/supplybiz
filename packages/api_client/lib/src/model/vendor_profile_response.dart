//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/vendor_settings_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_profile_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorProfileResponse {
  /// Returns a new [VendorProfileResponse] instance.
  VendorProfileResponse({
    required this.id,
    required this.categoryId,
    required this.onboardingStep,
    required this.kycStatus,
    required this.businessName,
    required this.gstin,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.shopPhotoMediaId,
    required this.settings,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'categoryId',
    required: true,
    includeIfNull: false,
  )
  final String categoryId;

  /// Next onboarding screen: 2 business, 3 KYC, 4 status. Never regresses.
  @JsonKey(
    name: r'onboardingStep',
    required: true,
    includeIfNull: false,
  )
  final int onboardingStep;

  @JsonKey(
    name: r'kycStatus',
    required: true,
    includeIfNull: false,
  )
  final String kycStatus;

  @JsonKey(
    name: r'businessName',
    required: true,
    includeIfNull: true,
  )
  final String? businessName;

  @JsonKey(
    name: r'gstin',
    required: true,
    includeIfNull: true,
  )
  final String? gstin;

  @JsonKey(
    name: r'addressLine',
    required: true,
    includeIfNull: true,
  )
  final String? addressLine;

  @JsonKey(
    name: r'city',
    required: true,
    includeIfNull: true,
  )
  final String? city;

  @JsonKey(
    name: r'state',
    required: true,
    includeIfNull: true,
  )
  final String? state;

  @JsonKey(
    name: r'pincode',
    required: true,
    includeIfNull: true,
  )
  final String? pincode;

  @JsonKey(
    name: r'latitude',
    required: true,
    includeIfNull: true,
  )
  final num? latitude;

  @JsonKey(
    name: r'longitude',
    required: true,
    includeIfNull: true,
  )
  final num? longitude;

  @JsonKey(
    name: r'shopPhotoMediaId',
    required: true,
    includeIfNull: true,
  )
  final String? shopPhotoMediaId;

  @JsonKey(
    name: r'settings',
    required: true,
    includeIfNull: false,
  )
  final VendorSettingsResponse settings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorProfileResponse &&
          other.id == id &&
          other.categoryId == categoryId &&
          other.onboardingStep == onboardingStep &&
          other.kycStatus == kycStatus &&
          other.businessName == businessName &&
          other.gstin == gstin &&
          other.addressLine == addressLine &&
          other.city == city &&
          other.state == state &&
          other.pincode == pincode &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.shopPhotoMediaId == shopPhotoMediaId &&
          other.settings == settings;

  @override
  int get hashCode =>
      id.hashCode +
      categoryId.hashCode +
      onboardingStep.hashCode +
      kycStatus.hashCode +
      (businessName == null ? 0 : businessName.hashCode) +
      (gstin == null ? 0 : gstin.hashCode) +
      (addressLine == null ? 0 : addressLine.hashCode) +
      (city == null ? 0 : city.hashCode) +
      (state == null ? 0 : state.hashCode) +
      (pincode == null ? 0 : pincode.hashCode) +
      (latitude == null ? 0 : latitude.hashCode) +
      (longitude == null ? 0 : longitude.hashCode) +
      (shopPhotoMediaId == null ? 0 : shopPhotoMediaId.hashCode) +
      settings.hashCode;

  factory VendorProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$VendorProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VendorProfileResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
