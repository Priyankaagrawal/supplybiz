// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_publication_ack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentPublicationAck _$PaymentPublicationAckFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentPublicationAck',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['version', 'published'],
        );
        final val = PaymentPublicationAck(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          published: $checkedConvert('published', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentPublicationAckToJson(
        PaymentPublicationAck instance) =>
    <String, dynamic>{
      'version': instance.version,
      'published': instance.published,
    };
