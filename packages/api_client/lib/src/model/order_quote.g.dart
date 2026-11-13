// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderQuote _$OrderQuoteFromJson(Map<String, dynamic> json) => $checkedCreate(
      'OrderQuote',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'serverTime',
            'businessDate',
            'sameDayCutoff',
            'items',
            'subtotalPaise',
            'deliveryChargePaise',
            'discountPaise',
            'totalPaise'
          ],
        );
        final val = OrderQuote(
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          sameDayCutoff: $checkedConvert('sameDayCutoff', (v) => v as String?),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      OrderPricedLine.fromJson(e as Map<String, dynamic>))
                  .toList()),
          subtotalPaise: $checkedConvert('subtotalPaise', (v) => v as String),
          deliveryChargePaise:
              $checkedConvert('deliveryChargePaise', (v) => v as String),
          discountPaise: $checkedConvert('discountPaise', (v) => v as String),
          totalPaise: $checkedConvert('totalPaise', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$OrderQuoteToJson(OrderQuote instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
      'sameDayCutoff': instance.sameDayCutoff,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'subtotalPaise': instance.subtotalPaise,
      'deliveryChargePaise': instance.deliveryChargePaise,
      'discountPaise': instance.discountPaise,
      'totalPaise': instance.totalPaise,
    };
