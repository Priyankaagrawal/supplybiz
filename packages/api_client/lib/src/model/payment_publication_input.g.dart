// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_publication_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentPublicationInput _$PaymentPublicationInputFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentPublicationInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version', 'publish'],
        );
        final val = PaymentPublicationInput(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          publish: $checkedConvert('publish', (v) => v as bool),
          upiId: $checkedConvert('upiId', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentPublicationInputToJson(
        PaymentPublicationInput instance) =>
    <String, dynamic>{
      'version': instance.version,
      'publish': instance.publish,
      if (instance.upiId case final value?) 'upiId': value,
    };
