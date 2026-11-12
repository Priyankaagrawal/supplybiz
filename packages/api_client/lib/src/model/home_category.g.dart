// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeCategory _$HomeCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HomeCategory',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'code',
            'name',
            'icon',
            'status',
            'available',
            'productTypes'
          ],
        );
        final val = HomeCategory(
          id: $checkedConvert('id', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          icon: $checkedConvert('icon', (v) => v as String?),
          status: $checkedConvert(
              'status', (v) => $enumDecode(_$HomeCategoryStatusEnumEnumMap, v)),
          available: $checkedConvert('available', (v) => v as bool),
          productTypes: $checkedConvert('productTypes',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$HomeCategoryToJson(HomeCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'icon': instance.icon,
      'status': _$HomeCategoryStatusEnumEnumMap[instance.status]!,
      'available': instance.available,
      'productTypes': instance.productTypes,
    };

const _$HomeCategoryStatusEnumEnumMap = {
  HomeCategoryStatusEnum.ENABLED: 'ENABLED',
  HomeCategoryStatusEnum.COMING_SOON: 'COMING_SOON',
};
