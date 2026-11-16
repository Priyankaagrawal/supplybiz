// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_revision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionRevision _$SubscriptionRevisionFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionRevision',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'version',
            'effectiveFrom',
            'qty',
            'weekdays',
            'timeSlot',
            'status',
            'action',
            'reason'
          ],
        );
        final val = SubscriptionRevision(
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          effectiveFrom: $checkedConvert(
              'effectiveFrom', (v) => DateTime.parse(v as String)),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
          weekdays: $checkedConvert('weekdays',
              (v) => (v as List<dynamic>).map((e) => e as num).toList()),
          timeSlot: $checkedConvert('timeSlot', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionRevisionToJson(
        SubscriptionRevision instance) =>
    <String, dynamic>{
      'version': instance.version,
      'effectiveFrom': instance.effectiveFrom.toIso8601String(),
      'qty': instance.qty,
      'weekdays': instance.weekdays,
      'timeSlot': instance.timeSlot,
      'status': instance.status,
      'action': instance.action,
      'reason': instance.reason,
    };
