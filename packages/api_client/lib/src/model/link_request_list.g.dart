// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_request_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkRequestList _$LinkRequestListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LinkRequestList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = LinkRequestList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      LinkRequestResponse.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$LinkRequestListToJson(LinkRequestList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
