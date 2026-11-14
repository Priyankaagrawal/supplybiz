// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentSummary _$PaymentSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentSummary',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'serverTime',
            'businessDate',
            'totalReceivablePaise',
            'thisMonthReceivedPaise'
          ],
        );
        final val = PaymentSummary(
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          totalReceivablePaise:
              $checkedConvert('totalReceivablePaise', (v) => v as String),
          thisMonthReceivedPaise:
              $checkedConvert('thisMonthReceivedPaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentSummaryToJson(PaymentSummary instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
      'totalReceivablePaise': instance.totalReceivablePaise,
      'thisMonthReceivedPaise': instance.thisMonthReceivedPaise,
    };
