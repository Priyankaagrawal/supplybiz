// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditPage _$AuditPageFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AuditPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'hasMore'],
        );
        final val = AuditPage(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => AuditRow.fromJson(e as Map<String, dynamic>))
                  .toList()),
          hasMore: $checkedConvert('hasMore', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$AuditPageToJson(AuditPage instance) => <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'hasMore': instance.hasMore,
    };
