// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'khata_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KhataAccount _$KhataAccountFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KhataAccount',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'kind', 'name', 'balancePaise', 'status'],
        );
        final val = KhataAccount(
          id: $checkedConvert('id', (v) => v as String),
          kind: $checkedConvert(
              'kind', (v) => $enumDecode(_$KhataAccountKindEnumEnumMap, v)),
          name: $checkedConvert('name', (v) => v as String),
          balancePaise: $checkedConvert('balancePaise', (v) => v as String),
          status: $checkedConvert(
              'status', (v) => $enumDecode(_$KhataAccountStatusEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$KhataAccountToJson(KhataAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$KhataAccountKindEnumEnumMap[instance.kind]!,
      'name': instance.name,
      'balancePaise': instance.balancePaise,
      'status': _$KhataAccountStatusEnumEnumMap[instance.status]!,
    };

const _$KhataAccountKindEnumEnumMap = {
  KhataAccountKindEnum.VENDOR: 'VENDOR',
  KhataAccountKindEnum.PERSONAL: 'PERSONAL',
};

const _$KhataAccountStatusEnumEnumMap = {
  KhataAccountStatusEnum.RECEIVABLE: 'RECEIVABLE',
  KhataAccountStatusEnum.PAYABLE: 'PAYABLE',
  KhataAccountStatusEnum.SETTLED: 'SETTLED',
};
