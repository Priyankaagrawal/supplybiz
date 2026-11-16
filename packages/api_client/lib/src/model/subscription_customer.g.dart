// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionCustomer _$SubscriptionCustomerFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionCustomer',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'name',
            'mobile',
            'status',
            'activeSubscriptions',
            'pausedSubscriptions'
          ],
        );
        final val = SubscriptionCustomer(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          mobile: $checkedConvert('mobile', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          activeSubscriptions:
              $checkedConvert('activeSubscriptions', (v) => (v as num).toInt()),
          pausedSubscriptions:
              $checkedConvert('pausedSubscriptions', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionCustomerToJson(
        SubscriptionCustomer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'mobile': instance.mobile,
      'status': instance.status,
      'activeSubscriptions': instance.activeSubscriptions,
      'pausedSubscriptions': instance.pausedSubscriptions,
    };
