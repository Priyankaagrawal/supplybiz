// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_request_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkRequestResponse _$LinkRequestResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LinkRequestResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'vendorId', 'businessName'],
        );
        final val = LinkRequestResponse(
          id: $checkedConvert('id', (v) => v as String),
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          businessName: $checkedConvert('businessName', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$LinkRequestResponseToJson(
        LinkRequestResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'businessName': instance.businessName,
    };
