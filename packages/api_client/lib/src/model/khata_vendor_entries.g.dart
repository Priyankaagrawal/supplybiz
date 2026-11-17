// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'khata_vendor_entries.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KhataVendorEntries _$KhataVendorEntriesFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KhataVendorEntries',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'vendorId',
            'vendorName',
            'month',
            'duePaise',
            'openingDuePaise',
            'closingDuePaise',
            'monthDebitPaise',
            'monthCreditPaise',
            'monthPaidPaise',
            'accounts',
            'items',
            'total',
            'serverTime',
            'businessDate'
          ],
        );
        final val = KhataVendorEntries(
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          vendorName: $checkedConvert('vendorName', (v) => v as String),
          month: $checkedConvert('month', (v) => v as String),
          duePaise: $checkedConvert('duePaise', (v) => v as String),
          openingDuePaise:
              $checkedConvert('openingDuePaise', (v) => v as String),
          closingDuePaise:
              $checkedConvert('closingDuePaise', (v) => v as String),
          monthDebitPaise:
              $checkedConvert('monthDebitPaise', (v) => v as String),
          monthCreditPaise:
              $checkedConvert('monthCreditPaise', (v) => v as String),
          monthPaidPaise: $checkedConvert('monthPaidPaise', (v) => v as String),
          accounts: $checkedConvert(
              'accounts',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      KhataBillingAccount.fromJson(e as Map<String, dynamic>))
                  .toList()),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      KhataLedgerEntry.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$KhataVendorEntriesToJson(KhataVendorEntries instance) =>
    <String, dynamic>{
      'vendorId': instance.vendorId,
      'vendorName': instance.vendorName,
      'month': instance.month,
      'duePaise': instance.duePaise,
      'openingDuePaise': instance.openingDuePaise,
      'closingDuePaise': instance.closingDuePaise,
      'monthDebitPaise': instance.monthDebitPaise,
      'monthCreditPaise': instance.monthCreditPaise,
      'monthPaidPaise': instance.monthPaidPaise,
      'accounts': instance.accounts.map((e) => e.toJson()).toList(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
    };
