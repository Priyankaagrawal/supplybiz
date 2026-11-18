// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorCollection _$VendorCollectionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorCollection',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'vendorCustomerId',
            'customerName',
            'amountPaise',
            'method',
            'entryDate',
            'createdAt',
            'reversal',
            'source'
          ],
        );
        final val = VendorCollection(
          id: $checkedConvert('id', (v) => v as String),
          vendorCustomerId:
              $checkedConvert('vendorCustomerId', (v) => v as String),
          customerName: $checkedConvert('customerName', (v) => v as String),
          amountPaise: $checkedConvert('amountPaise', (v) => v as String),
          method: $checkedConvert('method', (v) => v as String),
          entryDate: $checkedConvert('entryDate', (v) => v as String),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
          reversal: $checkedConvert('reversal', (v) => v as bool),
          source_: $checkedConvert('source', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'source_': 'source'},
    );

Map<String, dynamic> _$VendorCollectionToJson(VendorCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorCustomerId': instance.vendorCustomerId,
      'customerName': instance.customerName,
      'amountPaise': instance.amountPaise,
      'method': instance.method,
      'entryDate': instance.entryDate,
      'createdAt': instance.createdAt,
      'reversal': instance.reversal,
      'source': instance.source_,
    };
