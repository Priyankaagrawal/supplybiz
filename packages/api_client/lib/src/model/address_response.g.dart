// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressResponse _$AddressResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AddressResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'label',
            'line1',
            'line2',
            'landmark',
            'city',
            'state',
            'pincode',
            'latitude',
            'longitude',
            'isDefault',
            'id'
          ],
        );
        final val = AddressResponse(
          label: $checkedConvert('label', (v) => v as String),
          line1: $checkedConvert('line1', (v) => v as String),
          line2: $checkedConvert('line2', (v) => v as String),
          landmark: $checkedConvert('landmark', (v) => v as String),
          city: $checkedConvert('city', (v) => v as String),
          state: $checkedConvert('state', (v) => v as String),
          pincode: $checkedConvert('pincode', (v) => v as String),
          latitude: $checkedConvert('latitude', (v) => v as num),
          longitude: $checkedConvert('longitude', (v) => v as num),
          isDefault: $checkedConvert('isDefault', (v) => v as bool),
          id: $checkedConvert('id', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$AddressResponseToJson(AddressResponse instance) =>
    <String, dynamic>{
      'label': instance.label,
      'line1': instance.line1,
      'line2': instance.line2,
      'landmark': instance.landmark,
      'city': instance.city,
      'state': instance.state,
      'pincode': instance.pincode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'isDefault': instance.isDefault,
      'id': instance.id,
    };
