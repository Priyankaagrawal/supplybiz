// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_export_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivacyExportInput _$PrivacyExportInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PrivacyExportInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['userId', 'identityVerified', 'reason'],
        );
        final val = PrivacyExportInput(
          userId: $checkedConvert('userId', (v) => v as String),
          identityVerified:
              $checkedConvert('identityVerified', (v) => v as bool),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PrivacyExportInputToJson(PrivacyExportInput instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'identityVerified': instance.identityVerified,
      'reason': instance.reason,
    };
