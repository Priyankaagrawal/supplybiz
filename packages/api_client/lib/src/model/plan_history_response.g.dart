// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_history_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanHistoryResponse _$PlanHistoryResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanHistoryResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items', 'total'],
        );
        final val = PlanHistoryResponse(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => PlanHistoryRow.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanHistoryResponseToJson(
        PlanHistoryResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
