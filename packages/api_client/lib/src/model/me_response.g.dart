// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeResponse _$MeResponseFromJson(Map<String, dynamic> json) => $checkedCreate(
      'MeResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'mobile',
            'name',
            'language',
            'roles',
            'activeRole'
          ],
        );
        final val = MeResponse(
          id: $checkedConvert('id', (v) => v as String),
          mobile: $checkedConvert('mobile', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String?),
          language: $checkedConvert('language',
              (v) => $enumDecode(_$MeResponseLanguageEnumEnumMap, v)),
          roles: $checkedConvert(
              'roles',
              (v) => (v as List<dynamic>)
                  .map((e) => $enumDecode(_$MeResponseRolesEnumEnumMap, e))
                  .toList()),
          activeRole: $checkedConvert('activeRole',
              (v) => $enumDecodeNullable(_$MeResponseActiveRoleEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$MeResponseToJson(MeResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mobile': instance.mobile,
      'name': instance.name,
      'language': _$MeResponseLanguageEnumEnumMap[instance.language]!,
      'roles':
          instance.roles.map((e) => _$MeResponseRolesEnumEnumMap[e]!).toList(),
      'activeRole': _$MeResponseActiveRoleEnumEnumMap[instance.activeRole],
    };

const _$MeResponseLanguageEnumEnumMap = {
  MeResponseLanguageEnum.EN: 'EN',
  MeResponseLanguageEnum.HI: 'HI',
};

const _$MeResponseRolesEnumEnumMap = {
  MeResponseRolesEnum.CUSTOMER: 'CUSTOMER',
  MeResponseRolesEnum.VENDOR: 'VENDOR',
};

const _$MeResponseActiveRoleEnumEnumMap = {
  MeResponseActiveRoleEnum.CUSTOMER: 'CUSTOMER',
  MeResponseActiveRoleEnum.VENDOR: 'VENDOR',
};
