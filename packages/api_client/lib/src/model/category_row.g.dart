// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryRow _$CategoryRowFromJson(Map<String, dynamic> json) => $checkedCreate(
      'CategoryRow',
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
            'productTypes',
            'id'
          ],
        );
        final val = CategoryRow(
          code: $checkedConvert('code', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          icon: $checkedConvert('icon', (v) => v as String),
          type: $checkedConvert(
              'type', (v) => $enumDecode(_$CategoryRowTypeEnumEnumMap, v)),
          status: $checkedConvert(
              'status', (v) => $enumDecode(_$CategoryRowStatusEnumEnumMap, v)),
          sortOrder: $checkedConvert('sortOrder', (v) => v as num),
          productTypes: $checkedConvert('productTypes',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          id: $checkedConvert('id', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$CategoryRowToJson(CategoryRow instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'icon': instance.icon,
      'type': _$CategoryRowTypeEnumEnumMap[instance.type]!,
      'status': _$CategoryRowStatusEnumEnumMap[instance.status]!,
      'sortOrder': instance.sortOrder,
      'productTypes': instance.productTypes,
      'id': instance.id,
    };

const _$CategoryRowTypeEnumEnumMap = {
  CategoryRowTypeEnum.SUPPLY: 'SUPPLY',
  CategoryRowTypeEnum.BILL: 'BILL',
};

const _$CategoryRowStatusEnumEnumMap = {
  CategoryRowStatusEnum.ENABLED: 'ENABLED',
  CategoryRowStatusEnum.COMING_SOON: 'COMING_SOON',
  CategoryRowStatusEnum.HIDDEN: 'HIDDEN',
};
