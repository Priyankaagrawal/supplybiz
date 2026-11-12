// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerHome _$CustomerHomeFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CustomerHome',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'serverTime',
            'businessDate',
            'categories',
            'deliveries',
            'nextCursor'
          ],
        );
        final val = CustomerHome(
          serverTime:
              $checkedConvert('serverTime', (v) => DateTime.parse(v as String)),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          categories: $checkedConvert(
              'categories',
              (v) => (v as List<dynamic>)
                  .map((e) => HomeCategory.fromJson(e as Map<String, dynamic>))
                  .toList()),
          deliveries: $checkedConvert(
              'deliveries',
              (v) => (v as List<dynamic>)
                  .map((e) => HomeDelivery.fromJson(e as Map<String, dynamic>))
                  .toList()),
          nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$CustomerHomeToJson(CustomerHome instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime.toIso8601String(),
      'businessDate': instance.businessDate.toIso8601String(),
      'categories': instance.categories.map((e) => e.toJson()).toList(),
      'deliveries': instance.deliveries.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
