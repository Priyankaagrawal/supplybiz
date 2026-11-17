// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailabilityResponse _$AvailabilityResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'AvailabilityResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'version',
            'acceptingToday',
            'deliveryPaused',
            'deliveryPausedUntil',
            'canResume',
            'canReduceActivity',
            'serverTime',
            'businessDate'
          ],
        );
        final val = AvailabilityResponse(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          acceptingToday: $checkedConvert('acceptingToday', (v) => v as bool),
          deliveryPaused: $checkedConvert('deliveryPaused', (v) => v as bool),
          deliveryPausedUntil: $checkedConvert('deliveryPausedUntil',
              (v) => v == null ? null : DateTime.parse(v as String)),
          canResume: $checkedConvert('canResume', (v) => v as bool),
          canReduceActivity:
              $checkedConvert('canReduceActivity', (v) => v as bool),
          serverTime: $checkedConvert('serverTime', (v) => v as String),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AvailabilityResponseToJson(
        AvailabilityResponse instance) =>
    <String, dynamic>{
      'version': instance.version,
      'acceptingToday': instance.acceptingToday,
      'deliveryPaused': instance.deliveryPaused,
      'deliveryPausedUntil': instance.deliveryPausedUntil?.toIso8601String(),
      'canResume': instance.canResume,
      'canReduceActivity': instance.canReduceActivity,
      'serverTime': instance.serverTime,
      'businessDate': instance.businessDate.toIso8601String(),
    };
