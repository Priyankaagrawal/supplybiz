// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_profile_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorProfileResponse _$VendorProfileResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorProfileResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'categoryId',
            'onboardingStep',
            'kycStatus',
            'businessName',
            'gstin',
            'addressLine',
            'city',
            'state',
            'pincode',
            'latitude',
            'longitude',
            'shopPhotoMediaId',
            'settings'
          ],
        );
        final val = VendorProfileResponse(
          id: $checkedConvert('id', (v) => v as String),
          categoryId: $checkedConvert('categoryId', (v) => v as String),
          onboardingStep:
              $checkedConvert('onboardingStep', (v) => (v as num).toInt()),
          kycStatus: $checkedConvert('kycStatus', (v) => v as String),
          businessName: $checkedConvert('businessName', (v) => v as String?),
          gstin: $checkedConvert('gstin', (v) => v as String?),
          addressLine: $checkedConvert('addressLine', (v) => v as String?),
          city: $checkedConvert('city', (v) => v as String?),
          state: $checkedConvert('state', (v) => v as String?),
          pincode: $checkedConvert('pincode', (v) => v as String?),
          latitude: $checkedConvert('latitude', (v) => v as num?),
          longitude: $checkedConvert('longitude', (v) => v as num?),
          shopPhotoMediaId:
              $checkedConvert('shopPhotoMediaId', (v) => v as String?),
          settings: $checkedConvert(
              'settings',
              (v) =>
                  VendorSettingsResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorProfileResponseToJson(
        VendorProfileResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'onboardingStep': instance.onboardingStep,
      'kycStatus': instance.kycStatus,
      'businessName': instance.businessName,
      'gstin': instance.gstin,
      'addressLine': instance.addressLine,
      'city': instance.city,
      'state': instance.state,
      'pincode': instance.pincode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'shopPhotoMediaId': instance.shopPhotoMediaId,
      'settings': instance.settings.toJson(),
    };
