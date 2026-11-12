// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoveryPage _$DiscoveryPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DiscoveryPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'nextCursor'],
        );
        final val = DiscoveryPage(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      DiscoveredVendor.fromJson(e as Map<String, dynamic>))
                  .toList()),
          nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$DiscoveryPageToJson(DiscoveryPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
