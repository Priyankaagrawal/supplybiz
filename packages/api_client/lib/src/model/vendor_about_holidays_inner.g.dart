// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_about_holidays_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorAboutHolidaysInner _$VendorAboutHolidaysInnerFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorAboutHolidaysInner',
      json,
      ($checkedConvert) {
        final val = VendorAboutHolidaysInner(
          date: $checkedConvert(
              'date', (v) => v == null ? null : DateTime.parse(v as String)),
          reason: $checkedConvert('reason', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorAboutHolidaysInnerToJson(
        VendorAboutHolidaysInner instance) =>
    <String, dynamic>{
      if (instance.date?.toIso8601String() case final value?) 'date': value,
      if (instance.reason case final value?) 'reason': value,
    };
