// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleResponse _$SaleResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SaleResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'saleNo',
            'vendorCustomerId',
            'totalPaise',
            'paidPaise',
            'balancePaise',
            'paymentStatus',
            'paymentMethod',
            'businessDate',
            'createdAt',
            'clientCreatedAt',
            'items'
          ],
        );
        final val = SaleResponse(
          id: $checkedConvert('id', (v) => v as String),
          saleNo: $checkedConvert('saleNo', (v) => v as String),
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String?),
          totalPaise: $checkedConvert('totalPaise', (v) => v as String),
          paidPaise: $checkedConvert('paidPaise', (v) => v as String),
          balancePaise: $checkedConvert('balancePaise', (v) => v as String),
          paymentStatus: $checkedConvert('paymentStatus',
              (v) => $enumDecode(_$SaleResponsePaymentStatusEnumEnumMap, v)),
          paymentMethod: $checkedConvert('paymentMethod',
              (v) => $enumDecode(_$SaleResponsePaymentMethodEnumEnumMap, v)),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          createdAt:
              $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
          clientCreatedAt: $checkedConvert('clientCreatedAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      SaleItemResponse.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SaleResponseToJson(SaleResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'saleNo': instance.saleNo,
      'vendorCustomerId': instance.vendorCustomerId,
      'totalPaise': instance.totalPaise,
      'paidPaise': instance.paidPaise,
      'balancePaise': instance.balancePaise,
      'paymentStatus':
          _$SaleResponsePaymentStatusEnumEnumMap[instance.paymentStatus]!,
      'paymentMethod':
          _$SaleResponsePaymentMethodEnumEnumMap[instance.paymentMethod]!,
      'businessDate': instance.businessDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'clientCreatedAt': instance.clientCreatedAt?.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$SaleResponsePaymentStatusEnumEnumMap = {
  SaleResponsePaymentStatusEnum.PAID: 'PAID',
  SaleResponsePaymentStatusEnum.UNPAID: 'UNPAID',
};

const _$SaleResponsePaymentMethodEnumEnumMap = {
  SaleResponsePaymentMethodEnum.CASH: 'CASH',
  SaleResponsePaymentMethodEnum.UPI: 'UPI',
  SaleResponsePaymentMethodEnum.OTHER: 'OTHER',
};
