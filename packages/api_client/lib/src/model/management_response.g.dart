// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'management_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagementResponse _$ManagementResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ManagementResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'updatedAt'],
        );
        final val = ManagementResponse(
          id: $checkedConvert('id', (v) => v as String),
          updatedAt:
              $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
          status: $checkedConvert('status', (v) => v as String?),
          isSuspended: $checkedConvert('isSuspended', (v) => v as bool?),
          badges: $checkedConvert('badges',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ManagementResponseToJson(ManagementResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'updatedAt': instance.updatedAt.toIso8601String(),
      if (instance.status case final value?) 'status': value,
      if (instance.isSuspended case final value?) 'isSuspended': value,
      if (instance.badges case final value?) 'badges': value,
    };
