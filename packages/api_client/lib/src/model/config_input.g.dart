// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigInput _$ConfigInputFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ConfigInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'expectedUpdatedAt',
            'minVersionAndroid',
            'flags'
          ],
        );
        final val = ConfigInput(
          expectedUpdatedAt:
              $checkedConvert('expectedUpdatedAt', (v) => v as String?),
          minVersionAndroid:
              $checkedConvert('minVersionAndroid', (v) => v as String),
          flags:
              $checkedConvert('flags', (v) => Map<String, bool>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ConfigInputToJson(ConfigInput instance) =>
    <String, dynamic>{
      'expectedUpdatedAt': instance.expectedUpdatedAt,
      'minVersionAndroid': instance.minVersionAndroid,
      'flags': instance.flags,
    };
