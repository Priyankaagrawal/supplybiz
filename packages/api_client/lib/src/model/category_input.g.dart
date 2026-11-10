// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryInput _$CategoryInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CategoryInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'code',
            'name',
            'icon',
            'type',
            'status',
            'sortOrder',
            'productTypes'
          ],
        );
        final val = CategoryInput(
          code: $checkedConvert('code', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          icon: $checkedConvert('icon', (v) => v as String),
          type: $checkedConvert(
              'type', (v) => $enumDecode(_$CategoryInputTypeEnumEnumMap, v)),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$CategoryInputStatusEnumEnumMap, v)),
          sortOrder: $checkedConvert('sortOrder', (v) => v as num),
          productTypes: $checkedConvert('productTypes',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$CategoryInputToJson(CategoryInput instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'icon': instance.icon,
      'type': _$CategoryInputTypeEnumEnumMap[instance.type]!,
      'status': _$CategoryInputStatusEnumEnumMap[instance.status]!,
      'sortOrder': instance.sortOrder,
      'productTypes': instance.productTypes,
    };

const _$CategoryInputTypeEnumEnumMap = {
  CategoryInputTypeEnum.SUPPLY: 'SUPPLY',
  CategoryInputTypeEnum.BILL: 'BILL',
};

const _$CategoryInputStatusEnumEnumMap = {
  CategoryInputStatusEnum.ENABLED: 'ENABLED',
  CategoryInputStatusEnum.COMING_SOON: 'COMING_SOON',
  CategoryInputStatusEnum.HIDDEN: 'HIDDEN',
};
