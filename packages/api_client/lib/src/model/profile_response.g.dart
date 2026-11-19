// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProfileResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'mobile',
            'name',
            'email',
            'photoMediaId',
            'updatedAt'
          ],
        );
        final val = ProfileResponse(
          id: $checkedConvert('id', (v) => v as String),
          mobile: $checkedConvert('mobile', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          photoMediaId: $checkedConvert('photoMediaId', (v) => v as String?),
          updatedAt:
              $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProfileResponseToJson(ProfileResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mobile': instance.mobile,
      'name': instance.name,
      'email': instance.email,
      'photoMediaId': instance.photoMediaId,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
