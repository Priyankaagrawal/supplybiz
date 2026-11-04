// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoleDto _$RoleDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
      'RoleDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['role'],
        );
        final val = RoleDto(
          role: $checkedConvert(
              'role', (v) => $enumDecode(_$RoleDtoRoleEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$RoleDtoToJson(RoleDto instance) => <String, dynamic>{
      'role': _$RoleDtoRoleEnumEnumMap[instance.role]!,
    };

const _$RoleDtoRoleEnumEnumMap = {
  RoleDtoRoleEnum.CUSTOMER: 'CUSTOMER',
  RoleDtoRoleEnum.VENDOR: 'VENDOR',
};
