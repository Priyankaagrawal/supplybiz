// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckoutOptions _$CheckoutOptionsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CheckoutOptions',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'serverTime',
            'businessDate',
            'availableDates',
            'timeSlots',
            'sameDayCutoff'
          ],
        );
        final val = CheckoutOptions(
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert('businessDate', (v) => v as String),
          availableDates: $checkedConvert('availableDates',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          timeSlots: $checkedConvert('timeSlots',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          sameDayCutoff: $checkedConvert('sameDayCutoff', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$CheckoutOptionsToJson(CheckoutOptions instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate,
      'availableDates': instance.availableDates,
      'timeSlots': instance.timeSlots,
      'sameDayCutoff': instance.sameDayCutoff,
    };
