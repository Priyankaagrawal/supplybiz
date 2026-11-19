// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_admin_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAdminInput _$CreateAdminInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreateAdminInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['email', 'password', 'role', 'reason'],
        );
        final val = CreateAdminInput(
          email: $checkedConvert('email', (v) => v as String),
          password: $checkedConvert('password', (v) => v as String),
          role: $checkedConvert(
              'role', (v) => $enumDecode(_$CreateAdminInputRoleEnumEnumMap, v)),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$CreateAdminInputToJson(CreateAdminInput instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'role': _$CreateAdminInputRoleEnumEnumMap[instance.role]!,
      'reason': instance.reason,
    };

const _$CreateAdminInputRoleEnumEnumMap = {
  CreateAdminInputRoleEnum.SUPER_ADMIN: 'SUPER_ADMIN',
  CreateAdminInputRoleEnum.OPS: 'OPS',
  CreateAdminInputRoleEnum.SUPPORT: 'SUPPORT',
  CreateAdminInputRoleEnum.FINANCE: 'FINANCE',
};
