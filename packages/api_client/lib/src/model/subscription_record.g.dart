// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionRecord _$SubscriptionRecordFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionRecord',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'version',
            'status',
            'effectiveFrom',
            'vendorId',
            'vendorCustomerId',
            'productId',
            'productName',
            'qty',
            'weekdays',
            'timeSlot',
            'startDate',
            'endDate',
            'addressSnapshot',
            'paymentMethod',
            'createdBy',
            'dailyAmountPaise',
            'monthlyEstimatePaise',
            'estimateMonth',
            'revisions',
            'pauses',
            'skips'
          ],
        );
        final val = SubscriptionRecord(
          id: $checkedConvert('id', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          status: $checkedConvert('status', (v) => v as String),
          effectiveFrom: $checkedConvert(
              'effectiveFrom', (v) => DateTime.parse(v as String)),
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String),
          productId: $checkedConvert('productId', (v) => v as String),
          productName: $checkedConvert('productName', (v) => v as String),
          qty: $checkedConvert('qty', (v) => (v as num).toInt()),
          weekdays: $checkedConvert('weekdays',
              (v) => (v as List<dynamic>).map((e) => e as num).toList()),
          timeSlot: $checkedConvert('timeSlot', (v) => v as String),
          startDate:
              $checkedConvert('startDate', (v) => DateTime.parse(v as String)),
          endDate: $checkedConvert(
              'endDate', (v) => v == null ? null : DateTime.parse(v as String)),
          addressSnapshot: $checkedConvert(
              'addressSnapshot',
              (v) => (v as Map<String, dynamic>).map(
                    (k, e) => MapEntry(k, e as Object),
                  )),
          paymentMethod: $checkedConvert('paymentMethod', (v) => v as String),
          createdBy: $checkedConvert('createdBy', (v) => v as String),
          dailyAmountPaise:
              $checkedConvert('dailyAmountPaise', (v) => v as String),
          monthlyEstimatePaise:
              $checkedConvert('monthlyEstimatePaise', (v) => v as String),
          estimateMonth: $checkedConvert('estimateMonth', (v) => v as String),
          revisions: $checkedConvert(
              'revisions',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      SubscriptionRevision.fromJson(e as Map<String, dynamic>))
                  .toList()),
          pauses: $checkedConvert(
              'pauses',
              (v) => (v as List<dynamic>)
                  .map((e) => SubscriptionPauseRecord.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          skips: $checkedConvert('skips',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionRecordToJson(SubscriptionRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'status': instance.status,
      'effectiveFrom': instance.effectiveFrom.toIso8601String(),
      'vendorId': instance.vendorId,
      'vendorCustomerId': instance.vendorCustomerId,
      'productId': instance.productId,
      'productName': instance.productName,
      'qty': instance.qty,
      'weekdays': instance.weekdays,
      'timeSlot': instance.timeSlot,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'addressSnapshot': instance.addressSnapshot,
      'paymentMethod': instance.paymentMethod,
      'createdBy': instance.createdBy,
      'dailyAmountPaise': instance.dailyAmountPaise,
      'monthlyEstimatePaise': instance.monthlyEstimatePaise,
      'estimateMonth': instance.estimateMonth,
      'revisions': instance.revisions.map((e) => e.toJson()).toList(),
      'pauses': instance.pauses.map((e) => e.toJson()).toList(),
      'skips': instance.skips,
    };
