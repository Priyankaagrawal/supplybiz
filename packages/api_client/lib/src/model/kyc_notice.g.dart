// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_notice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KycNotice _$KycNoticeFromJson(Map<String, dynamic> json) => $checkedCreate(
      'KycNotice',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'status', 'reason', 'createdAt'],
        );
        final val = KycNotice(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String?),
          createdAt:
              $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$KycNoticeToJson(KycNotice instance) => <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'reason': instance.reason,
      'createdAt': instance.createdAt.toIso8601String(),
    };
