// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressPatch _$AddressPatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AddressPatch',
      json,
      ($checkedConvert) {
        final val = AddressPatch(
          label: $checkedConvert('label', (v) => v as String?),
          line1: $checkedConvert('line1', (v) => v as String?),
          line2: $checkedConvert('line2', (v) => v as String?),
          landmark: $checkedConvert('landmark', (v) => v as String?),
          city: $checkedConvert('city', (v) => v as String?),
          state: $checkedConvert('state', (v) => v as String?),
          pincode: $checkedConvert('pincode', (v) => v as String?),
          latitude: $checkedConvert('latitude', (v) => v as num?),
          longitude: $checkedConvert('longitude', (v) => v as num?),
          isDefault: $checkedConvert('isDefault', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$AddressPatchToJson(AddressPatch instance) =>
    <String, dynamic>{
      if (instance.label case final value?) 'label': value,
      if (instance.line1 case final value?) 'line1': value,
      if (instance.line2 case final value?) 'line2': value,
      if (instance.landmark case final value?) 'landmark': value,
      if (instance.city case final value?) 'city': value,
      if (instance.state case final value?) 'state': value,
      if (instance.pincode case final value?) 'pincode': value,
      if (instance.latitude case final value?) 'latitude': value,
      if (instance.longitude case final value?) 'longitude': value,
      if (instance.isDefault case final value?) 'isDefault': value,
    };
