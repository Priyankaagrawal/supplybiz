// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InboxItem _$InboxItemFromJson(Map<String, dynamic> json) => $checkedCreate(
      'InboxItem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'role',
            'category',
            'type',
            'title',
            'body',
            'path',
            'readAt',
            'createdAt'
          ],
        );
        final val = InboxItem(
          id: $checkedConvert('id', (v) => v as String),
          role: $checkedConvert(
              'role', (v) => $enumDecode(_$InboxItemRoleEnumEnumMap, v)),
          category: $checkedConvert('category',
              (v) => $enumDecode(_$InboxItemCategoryEnumEnumMap, v)),
          type: $checkedConvert('type', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          body: $checkedConvert('body', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          readAt: $checkedConvert(
              'readAt', (v) => v == null ? null : DateTime.parse(v as String)),
          createdAt:
              $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$InboxItemToJson(InboxItem instance) => <String, dynamic>{
      'id': instance.id,
      'role': _$InboxItemRoleEnumEnumMap[instance.role]!,
      'category': _$InboxItemCategoryEnumEnumMap[instance.category]!,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'path': instance.path,
      'readAt': instance.readAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$InboxItemRoleEnumEnumMap = {
  InboxItemRoleEnum.VENDOR: 'VENDOR',
  InboxItemRoleEnum.CUSTOMER: 'CUSTOMER',
};

const _$InboxItemCategoryEnumEnumMap = {
  InboxItemCategoryEnum.ORDERS: 'ORDERS',
  InboxItemCategoryEnum.PAYMENTS: 'PAYMENTS',
  InboxItemCategoryEnum.DELIVERY: 'DELIVERY',
  InboxItemCategoryEnum.SYSTEM: 'SYSTEM',
};
