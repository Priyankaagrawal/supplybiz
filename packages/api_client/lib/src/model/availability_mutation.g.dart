// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_mutation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailabilityMutation _$AvailabilityMutationFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'AvailabilityMutation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['cancelledOrders', 'availability'],
        );
        final val = AvailabilityMutation(
          cancelledOrders:
              $checkedConvert('cancelledOrders', (v) => (v as num).toInt()),
          availability: $checkedConvert('availability',
              (v) => AvailabilityResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AvailabilityMutationToJson(
        AvailabilityMutation instance) =>
    <String, dynamic>{
      'cancelledOrders': instance.cancelledOrders,
      'availability': instance.availability.toJson(),
    };
