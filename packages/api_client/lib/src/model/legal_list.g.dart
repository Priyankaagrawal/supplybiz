// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegalList _$LegalListFromJson(Map<String, dynamic> json) => $checkedCreate(
      'LegalList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items'],
        );
        final val = LegalList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => LegalRow.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$LegalListToJson(LegalList instance) => <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
