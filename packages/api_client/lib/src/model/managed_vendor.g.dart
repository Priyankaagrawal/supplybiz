// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_vendor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedVendor _$ManagedVendorFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ManagedVendor',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'businessName',
            'account',
            'category',
            'city',
            'kycStatus',
            'isSuspended',
            'badges',
            'updatedAt'
          ],
        );
        final val = ManagedVendor(
          id: $checkedConvert('id', (v) => v as String),
          businessName: $checkedConvert('businessName', (v) => v as String?),
          account: $checkedConvert('account',
              (v) => ManagedCustomer.fromJson(v as Map<String, dynamic>)),
          category: $checkedConvert('category', (v) => v as String),
          city: $checkedConvert('city', (v) => v as String?),
          kycStatus: $checkedConvert('kycStatus', (v) => v as String),
          isSuspended: $checkedConvert('isSuspended', (v) => v as bool),
          badges: $checkedConvert('badges',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          updatedAt:
              $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ManagedVendorToJson(ManagedVendor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessName': instance.businessName,
      'account': instance.account.toJson(),
      'category': instance.category,
      'city': instance.city,
      'kycStatus': instance.kycStatus,
      'isSuspended': instance.isSuspended,
      'badges': instance.badges,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
