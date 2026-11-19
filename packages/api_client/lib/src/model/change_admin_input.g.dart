// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_admin_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangeAdminInput _$ChangeAdminInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ChangeAdminInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['role', 'status', 'expectedUpdatedAt', 'reason'],
        );
        final val = ChangeAdminInput(
          role: $checkedConvert(
              'role', (v) => $enumDecode(_$ChangeAdminInputRoleEnumEnumMap, v)),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$ChangeAdminInputStatusEnumEnumMap, v)),
          expectedUpdatedAt:
              $checkedConvert('expectedUpdatedAt', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ChangeAdminInputToJson(ChangeAdminInput instance) =>
    <String, dynamic>{
      'role': _$ChangeAdminInputRoleEnumEnumMap[instance.role]!,
      'status': _$ChangeAdminInputStatusEnumEnumMap[instance.status]!,
      'expectedUpdatedAt': instance.expectedUpdatedAt,
      'reason': instance.reason,
    };

const _$ChangeAdminInputRoleEnumEnumMap = {
  ChangeAdminInputRoleEnum.SUPER_ADMIN: 'SUPER_ADMIN',
  ChangeAdminInputRoleEnum.OPS: 'OPS',
  ChangeAdminInputRoleEnum.SUPPORT: 'SUPPORT',
  ChangeAdminInputRoleEnum.FINANCE: 'FINANCE',
};

const _$ChangeAdminInputStatusEnumEnumMap = {
  ChangeAdminInputStatusEnum.ACTIVE: 'ACTIVE',
  ChangeAdminInputStatusEnum.DISABLED: 'DISABLED',
};
