// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileInput _$ProfileInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProfileInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'expectedUpdatedAt',
            'name',
            'email',
            'photoMediaId'
          ],
        );
        final val = ProfileInput(
          expectedUpdatedAt:
              $checkedConvert('expectedUpdatedAt', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String?),
          photoMediaId: $checkedConvert('photoMediaId', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProfileInputToJson(ProfileInput instance) =>
    <String, dynamic>{
      'expectedUpdatedAt': instance.expectedUpdatedAt,
      'name': instance.name,
      'email': instance.email,
      'photoMediaId': instance.photoMediaId,
    };
