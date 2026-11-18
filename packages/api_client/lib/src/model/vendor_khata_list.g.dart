// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_khata_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorKhataList _$VendorKhataListFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorKhataList',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'items',
            'total',
            'totalReceivablePaise',
            'thisMonthReceivedPaise',
            'canAdjust',
            'canRecordPayment',
            'serverTime',
            'businessDate'
          ],
        );
        final val = VendorKhataList(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      VendorKhataAccount.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          totalReceivablePaise:
              $checkedConvert('totalReceivablePaise', (v) => v as String),
          thisMonthReceivedPaise:
              $checkedConvert('thisMonthReceivedPaise', (v) => v as String),
          canAdjust: $checkedConvert('canAdjust', (v) => v as bool),
          canRecordPayment:
              $checkedConvert('canRecordPayment', (v) => v as bool),
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert('businessDate', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorKhataListToJson(VendorKhataList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'totalReceivablePaise': instance.totalReceivablePaise,
      'thisMonthReceivedPaise': instance.thisMonthReceivedPaise,
      'canAdjust': instance.canAdjust,
      'canRecordPayment': instance.canRecordPayment,
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate,
    };
