// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_accounts_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminAccountsResponse _$AdminAccountsResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminAccountsResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = AdminAccountsResponse(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      AdminAccountResponse.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$AdminAccountsResponseToJson(
        AdminAccountsResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
