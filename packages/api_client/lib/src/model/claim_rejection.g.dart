// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_rejection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimRejection _$ClaimRejectionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ClaimRejection',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version', 'reason'],
        );
        final val = ClaimRejection(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ClaimRejectionToJson(ClaimRejection instance) =>
    <String, dynamic>{
      'version': instance.version,
      'reason': instance.reason,
    };
