// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KycResponse _$KycResponseFromJson(Map<String, dynamic> json) => $checkedCreate(
      'KycResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'vendorId',
            'status',
            'verificationMethod',
            'providerChecks',
            'submittedAt',
            'reviewedAt',
            'reviewerId',
            'reason',
            'aadhaarFrontMediaId',
            'aadhaarBackMediaId',
            'panMediaId',
            'panLast4',
            'accountLast4',
            'holderName',
            'bankName',
            'ifsc',
            'upiId'
          ],
        );
        final val = KycResponse(
          id: $checkedConvert('id', (v) => v as String),
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          verificationMethod:
              $checkedConvert('verificationMethod', (v) => v as String),
          providerChecks: $checkedConvert('providerChecks',
              (v) => $enumDecode(_$KycResponseProviderChecksEnumEnumMap, v)),
          submittedAt: $checkedConvert(
              'submittedAt', (v) => DateTime.parse(v as String)),
          reviewedAt: $checkedConvert('reviewedAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
          reviewerId: $checkedConvert('reviewerId', (v) => v as String?),
          reason: $checkedConvert('reason', (v) => v as String?),
          aadhaarFrontMediaId:
              $checkedConvert('aadhaarFrontMediaId', (v) => v as String),
          aadhaarBackMediaId:
              $checkedConvert('aadhaarBackMediaId', (v) => v as String),
          panMediaId: $checkedConvert('panMediaId', (v) => v as String),
          panLast4: $checkedConvert('panLast4', (v) => v as String),
          accountLast4: $checkedConvert('accountLast4', (v) => v as String),
          holderName: $checkedConvert('holderName', (v) => v as String),
          bankName: $checkedConvert('bankName', (v) => v as String),
          ifsc: $checkedConvert('ifsc', (v) => v as String),
          upiId: $checkedConvert('upiId', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$KycResponseToJson(KycResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'status': instance.status,
      'verificationMethod': instance.verificationMethod,
      'providerChecks':
          _$KycResponseProviderChecksEnumEnumMap[instance.providerChecks]!,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'reviewerId': instance.reviewerId,
      'reason': instance.reason,
      'aadhaarFrontMediaId': instance.aadhaarFrontMediaId,
      'aadhaarBackMediaId': instance.aadhaarBackMediaId,
      'panMediaId': instance.panMediaId,
      'panLast4': instance.panLast4,
      'accountLast4': instance.accountLast4,
      'holderName': instance.holderName,
      'bankName': instance.bankName,
      'ifsc': instance.ifsc,
      'upiId': instance.upiId,
    };

const _$KycResponseProviderChecksEnumEnumMap = {
  KycResponseProviderChecksEnum.NOT_RUN: 'NOT_RUN',
};
