// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_submission_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KycSubmissionDto _$KycSubmissionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KycSubmissionDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'aadhaarFrontMediaId',
            'aadhaarBackMediaId',
            'panMediaId',
            'pan',
            'holderName',
            'bankName',
            'accountNumber',
            'accountNumberConfirmation',
            'ifsc'
          ],
        );
        final val = KycSubmissionDto(
          aadhaarFrontMediaId:
              $checkedConvert('aadhaarFrontMediaId', (v) => v as String),
          aadhaarBackMediaId:
              $checkedConvert('aadhaarBackMediaId', (v) => v as String),
          panMediaId: $checkedConvert('panMediaId', (v) => v as String),
          pan: $checkedConvert('pan', (v) => v as String),
          holderName: $checkedConvert('holderName', (v) => v as String),
          bankName: $checkedConvert('bankName', (v) => v as String),
          accountNumber: $checkedConvert('accountNumber', (v) => v as String),
          accountNumberConfirmation:
              $checkedConvert('accountNumberConfirmation', (v) => v as String),
          ifsc: $checkedConvert('ifsc', (v) => v as String),
          upiId: $checkedConvert('upiId', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$KycSubmissionDtoToJson(KycSubmissionDto instance) =>
    <String, dynamic>{
      'aadhaarFrontMediaId': instance.aadhaarFrontMediaId,
      'aadhaarBackMediaId': instance.aadhaarBackMediaId,
      'panMediaId': instance.panMediaId,
      'pan': instance.pan,
      'holderName': instance.holderName,
      'bankName': instance.bankName,
      'accountNumber': instance.accountNumber,
      'accountNumberConfirmation': instance.accountNumberConfirmation,
      'ifsc': instance.ifsc,
      if (instance.upiId case final value?) 'upiId': value,
    };
