// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_problem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderProblem _$OrderProblemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderProblem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'type',
            'title',
            'status',
            'code',
            'detail',
            'requestId'
          ],
        );
        final val = OrderProblem(
          type: $checkedConvert('type', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          status: $checkedConvert('status', (v) => (v as num).toInt()),
          code: $checkedConvert('code', (v) => v as String),
          detail: $checkedConvert('detail', (v) => v as String),
          requestId: $checkedConvert('requestId', (v) => v as String),
          quote: $checkedConvert(
              'quote',
              (v) => v == null
                  ? null
                  : OrderQuote.fromJson(v as Map<String, dynamic>)),
          productId: $checkedConvert('productId', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderProblemToJson(OrderProblem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'status': instance.status,
      'code': instance.code,
      'detail': instance.detail,
      'requestId': instance.requestId,
      if (instance.quote?.toJson() case final value?) 'quote': value,
      if (instance.productId case final value?) 'productId': value,
    };
