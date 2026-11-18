// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_khata_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorKhataAccount _$VendorKhataAccountFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorKhataAccount',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'name',
            'mobile',
            'status',
            'archived',
            'totalDebitPaise',
            'totalCreditPaise',
            'totalPaidPaise',
            'duePaise'
          ],
        );
        final val = VendorKhataAccount(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          mobile: $checkedConvert('mobile', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          archived: $checkedConvert('archived', (v) => v as bool),
          totalDebitPaise:
              $checkedConvert('totalDebitPaise', (v) => v as String),
          totalCreditPaise:
              $checkedConvert('totalCreditPaise', (v) => v as String),
          totalPaidPaise: $checkedConvert('totalPaidPaise', (v) => v as String),
          duePaise: $checkedConvert('duePaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorKhataAccountToJson(VendorKhataAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'mobile': instance.mobile,
      'status': instance.status,
      'archived': instance.archived,
      'totalDebitPaise': instance.totalDebitPaise,
      'totalCreditPaise': instance.totalCreditPaise,
      'totalPaidPaise': instance.totalPaidPaise,
      'duePaise': instance.duePaise,
    };
