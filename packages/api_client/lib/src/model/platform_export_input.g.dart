// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_export_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlatformExportInput _$PlatformExportInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlatformExportInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['kind'],
        );
        final val = PlatformExportInput(
          kind: $checkedConvert('kind',
              (v) => $enumDecode(_$PlatformExportInputKindEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlatformExportInputToJson(
        PlatformExportInput instance) =>
    <String, dynamic>{
      'kind': _$PlatformExportInputKindEnumEnumMap[instance.kind]!,
    };

const _$PlatformExportInputKindEnumEnumMap = {
  PlatformExportInputKindEnum.PLATFORM_SUMMARY: 'PLATFORM_SUMMARY',
};
