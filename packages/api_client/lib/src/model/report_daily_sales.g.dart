// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_daily_sales.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportDailySales _$ReportDailySalesFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportDailySales',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'from',
            'to',
            'serverTime',
            'businessDate',
            'bucket',
            'items'
          ],
        );
        final val = ReportDailySales(
          from: $checkedConvert('from', (v) => DateTime.parse(v as String)),
          to: $checkedConvert('to', (v) => DateTime.parse(v as String)),
          serverTime:
              $checkedConvert('serverTime', (v) => DateTime.parse(v as String)),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          bucket: $checkedConvert('bucket',
              (v) => $enumDecode(_$ReportDailySalesBucketEnumEnumMap, v)),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ReportSalesBucket.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportDailySalesToJson(ReportDailySales instance) =>
    <String, dynamic>{
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
      'serverTime': instance.serverTime.toIso8601String(),
      'businessDate': instance.businessDate.toIso8601String(),
      'bucket': _$ReportDailySalesBucketEnumEnumMap[instance.bucket]!,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$ReportDailySalesBucketEnumEnumMap = {
  ReportDailySalesBucketEnum.DAY: 'DAY',
  ReportDailySalesBucketEnum.WEEK: 'WEEK',
};
