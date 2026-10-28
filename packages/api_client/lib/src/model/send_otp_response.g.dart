// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_otp_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendOtpResponse _$SendOtpResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SendOtpResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['resendAfterSec', 'expiresInSec'],
        );
        final val = SendOtpResponse(
          resendAfterSec:
              $checkedConvert('resendAfterSec', (v) => (v as num).toInt()),
          expiresInSec:
              $checkedConvert('expiresInSec', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SendOtpResponseToJson(SendOtpResponse instance) =>
    <String, dynamic>{
      'resendAfterSec': instance.resendAfterSec,
      'expiresInSec': instance.expiresInSec,
    };
