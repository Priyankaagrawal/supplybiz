// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KycPage _$KycPageFromJson(Map<String, dynamic> json) => $checkedCreate(
      'KycPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'hasMore'],
        );
        final val = KycPage(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => KycResponse.fromJson(e as Map<String, dynamic>))
                  .toList()),
          hasMore: $checkedConvert('hasMore', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$KycPageToJson(KycPage instance) => <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'hasMore': instance.hasMore,
    };
