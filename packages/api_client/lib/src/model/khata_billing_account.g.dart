// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'khata_billing_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KhataBillingAccount _$KhataBillingAccountFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KhataBillingAccount',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'vendorCustomerId',
            'duePaise',
            'maxClaimPaise',
            'canClaim'
          ],
        );
        final val = KhataBillingAccount(
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String),
          duePaise: $checkedConvert('duePaise', (v) => v as String),
          maxClaimPaise: $checkedConvert('maxClaimPaise', (v) => v as String),
          canClaim: $checkedConvert('canClaim', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$KhataBillingAccountToJson(
        KhataBillingAccount instance) =>
    <String, dynamic>{
      'vendorCustomerId': instance.vendorCustomerId,
      'duePaise': instance.duePaise,
      'maxClaimPaise': instance.maxClaimPaise,
      'canClaim': instance.canClaim,
    };
