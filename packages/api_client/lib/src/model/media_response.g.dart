// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaResponse _$MediaResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MediaResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['mediaId', 'status'],
        );
        final val = MediaResponse(
          mediaId: $checkedConvert('mediaId', (v) => v as String),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$MediaResponseStatusEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$MediaResponseToJson(MediaResponse instance) =>
    <String, dynamic>{
      'mediaId': instance.mediaId,
      'status': _$MediaResponseStatusEnumEnumMap[instance.status]!,
    };

const _$MediaResponseStatusEnumEnumMap = {
  MediaResponseStatusEnum.READY: 'READY',
};
