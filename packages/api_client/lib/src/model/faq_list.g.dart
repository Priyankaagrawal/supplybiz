// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqList _$FaqListFromJson(Map<String, dynamic> json) => $checkedCreate(
      'FaqList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = FaqList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => FaqRow.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$FaqListToJson(FaqList instance) => <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
