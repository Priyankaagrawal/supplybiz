// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_vendor_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanVendorRow _$PlanVendorRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanVendorRow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'businessName'],
        );
        final val = PlanVendorRow(
          id: $checkedConvert('id', (v) => v as String),
          businessName: $checkedConvert('businessName', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanVendorRowToJson(PlanVendorRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessName': instance.businessName,
    };
