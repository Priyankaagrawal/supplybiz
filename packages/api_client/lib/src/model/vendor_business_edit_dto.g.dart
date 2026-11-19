// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_business_edit_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorBusinessEditDto _$VendorBusinessEditDtoFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorBusinessEditDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'businessName',
            'addressLine',
            'city',
            'state',
            'pincode',
            'latitude',
            'longitude',
            'version'
          ],
        );
        final val = VendorBusinessEditDto(
          businessName: $checkedConvert('businessName', (v) => v as String),
          gstin: $checkedConvert('gstin', (v) => v as String?),
          addressLine: $checkedConvert('addressLine', (v) => v as String),
          city: $checkedConvert('city', (v) => v as String),
          state: $checkedConvert('state', (v) => v as String),
          pincode: $checkedConvert('pincode', (v) => v as String),
          latitude: $checkedConvert('latitude', (v) => v as num),
          longitude: $checkedConvert('longitude', (v) => v as num),
          shopPhotoMediaId:
              $checkedConvert('shopPhotoMediaId', (v) => v as String?),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorBusinessEditDtoToJson(
        VendorBusinessEditDto instance) =>
    <String, dynamic>{
      'businessName': instance.businessName,
      if (instance.gstin case final value?) 'gstin': value,
      'addressLine': instance.addressLine,
      'city': instance.city,
      'state': instance.state,
      'pincode': instance.pincode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      if (instance.shopPhotoMediaId case final value?)
        'shopPhotoMediaId': value,
      'version': instance.version,
    };
