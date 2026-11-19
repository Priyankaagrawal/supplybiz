// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_account_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminAccountResponse _$AdminAccountResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminAccountResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'email',
            'role',
            'status',
            'totpEnrolled',
            'updatedAt'
          ],
        );
        final val = AdminAccountResponse(
          id: $checkedConvert('id', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          role: $checkedConvert('role', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          totpEnrolled: $checkedConvert('totpEnrolled', (v) => v as bool),
          updatedAt: $checkedConvert('updatedAt', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$AdminAccountResponseToJson(
        AdminAccountResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'role': instance.role,
      'status': instance.status,
      'totpEnrolled': instance.totpEnrolled,
      'updatedAt': instance.updatedAt,
    };
