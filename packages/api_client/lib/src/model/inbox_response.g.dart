// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InboxResponse _$InboxResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InboxResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total', 'unreadCount'],
        );
        final val = InboxResponse(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => InboxItem.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          unreadCount:
              $checkedConvert('unreadCount', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$InboxResponseToJson(InboxResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'unreadCount': instance.unreadCount,
    };
