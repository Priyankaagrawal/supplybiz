// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_settlement_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerSettlementOptions _$CustomerSettlementOptionsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'CustomerSettlementOptions',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'vendorId',
            'payeeName',
            'upiId',
            'upiAvailable',
            'cashAvailable',
            'duePaise',
            'accounts'
          ],
        );
        final val = CustomerSettlementOptions(
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          payeeName: $checkedConvert('payeeName', (v) => v as String),
          upiId: $checkedConvert('upiId', (v) => v as String?),
          upiAvailable: $checkedConvert('upiAvailable', (v) => v as bool),
          cashAvailable: $checkedConvert('cashAvailable', (v) => v as bool),
          duePaise: $checkedConvert('duePaise', (v) => v as String),
          accounts: $checkedConvert(
              'accounts',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      KhataBillingAccount.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$CustomerSettlementOptionsToJson(
        CustomerSettlementOptions instance) =>
    <String, dynamic>{
      'vendorId': instance.vendorId,
      'payeeName': instance.payeeName,
      'upiId': instance.upiId,
      'upiAvailable': instance.upiAvailable,
      'cashAvailable': instance.cashAvailable,
      'duePaise': instance.duePaise,
      'accounts': instance.accounts.map((e) => e.toJson()).toList(),
    };
