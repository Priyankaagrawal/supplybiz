// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerResponse _$CustomerResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CustomerResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'name',
            'mobile',
            'email',
            'address',
            'preferredPayment',
            'status',
            'linkStatus',
            'userId'
          ],
        );
        final val = CustomerResponse(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          mobile: $checkedConvert('mobile', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String?),
          address: $checkedConvert('address', (v) => v as String),
          preferredPayment: $checkedConvert(
              'preferredPayment',
              (v) => $enumDecode(
                  _$CustomerResponsePreferredPaymentEnumEnumMap, v)),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$CustomerResponseStatusEnumEnumMap, v)),
          linkStatus: $checkedConvert('linkStatus',
              (v) => $enumDecode(_$CustomerResponseLinkStatusEnumEnumMap, v)),
          userId: $checkedConvert('userId', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$CustomerResponseToJson(CustomerResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'mobile': instance.mobile,
      'email': instance.email,
      'address': instance.address,
      'preferredPayment': _$CustomerResponsePreferredPaymentEnumEnumMap[
          instance.preferredPayment]!,
      'status': _$CustomerResponseStatusEnumEnumMap[instance.status]!,
      'linkStatus':
          _$CustomerResponseLinkStatusEnumEnumMap[instance.linkStatus]!,
      'userId': instance.userId,
    };

const _$CustomerResponsePreferredPaymentEnumEnumMap = {
  CustomerResponsePreferredPaymentEnum.CASH: 'CASH',
  CustomerResponsePreferredPaymentEnum.UPI: 'UPI',
  CustomerResponsePreferredPaymentEnum.BANK: 'BANK',
  CustomerResponsePreferredPaymentEnum.WALLET: 'WALLET',
};

const _$CustomerResponseStatusEnumEnumMap = {
  CustomerResponseStatusEnum.ACTIVE: 'ACTIVE',
  CustomerResponseStatusEnum.INACTIVE: 'INACTIVE',
};

const _$CustomerResponseLinkStatusEnumEnumMap = {
  CustomerResponseLinkStatusEnum.UNLINKED: 'UNLINKED',
  CustomerResponseLinkStatusEnum.LINKED: 'LINKED',
};
