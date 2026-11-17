// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_payment_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorPaymentDetails _$VendorPaymentDetailsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorPaymentDetails',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version', 'published', 'upiId', 'payeeName'],
        );
        final val = VendorPaymentDetails(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          published: $checkedConvert('published', (v) => v as bool),
          upiId: $checkedConvert('upiId', (v) => v as String?),
          payeeName: $checkedConvert('payeeName', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorPaymentDetailsToJson(
        VendorPaymentDetails instance) =>
    <String, dynamic>{
      'version': instance.version,
      'published': instance.published,
      'upiId': instance.upiId,
      'payeeName': instance.payeeName,
    };
