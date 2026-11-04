// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyOtpDto _$VerifyOtpDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VerifyOtpDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['mobile', 'code', 'device'],
        );
        final val = VerifyOtpDto(
          mobile: $checkedConvert('mobile', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String),
          device: $checkedConvert(
              'device', (v) => DeviceDto.fromJson(v as Map<String, dynamic>)),
          consent: $checkedConvert(
              'consent',
              (v) => v == null
                  ? null
                  : ConsentDto.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$VerifyOtpDtoToJson(VerifyOtpDto instance) =>
    <String, dynamic>{
      'mobile': instance.mobile,
      'code': instance.code,
      'device': instance.device.toJson(),
      if (instance.consent?.toJson() case final value?) 'consent': value,
    };
