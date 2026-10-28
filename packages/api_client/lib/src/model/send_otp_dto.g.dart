// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_otp_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendOtpDto _$SendOtpDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SendOtpDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['mobile'],
        );
        final val = SendOtpDto(
          mobile: $checkedConvert('mobile', (v) => v as String),
          channel: $checkedConvert('channel',
              (v) => $enumDecodeNullable(_$SendOtpDtoChannelEnumEnumMap, v)),
          appHash: $checkedConvert('appHash', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SendOtpDtoToJson(SendOtpDto instance) =>
    <String, dynamic>{
      'mobile': instance.mobile,
      if (_$SendOtpDtoChannelEnumEnumMap[instance.channel] case final value?)
        'channel': value,
      if (instance.appHash case final value?) 'appHash': value,
    };

const _$SendOtpDtoChannelEnumEnumMap = {
  SendOtpDtoChannelEnum.SMS: 'SMS',
  SendOtpDtoChannelEnum.WHATSAPP: 'WHATSAPP',
};
