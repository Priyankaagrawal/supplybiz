// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'khata_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KhataSummary _$KhataSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KhataSummary',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'totalReceivablePaise',
            'totalPayablePaise',
            'netBalancePaise',
            'items',
            'total',
            'serverTime',
            'businessDate'
          ],
        );
        final val = KhataSummary(
          totalReceivablePaise:
              $checkedConvert('totalReceivablePaise', (v) => v as String),
          totalPayablePaise:
              $checkedConvert('totalPayablePaise', (v) => v as String),
          netBalancePaise:
              $checkedConvert('netBalancePaise', (v) => v as String),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => KhataAccount.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$KhataSummaryToJson(KhataSummary instance) =>
    <String, dynamic>{
      'totalReceivablePaise': instance.totalReceivablePaise,
      'totalPayablePaise': instance.totalPayablePaise,
      'netBalancePaise': instance.netBalancePaise,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
    };
