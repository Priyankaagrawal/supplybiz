// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_requests_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivacyRequestsPage _$PrivacyRequestsPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PrivacyRequestsPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = PrivacyRequestsPage(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      PrivacyRequestRow.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$PrivacyRequestsPageToJson(
        PrivacyRequestsPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
