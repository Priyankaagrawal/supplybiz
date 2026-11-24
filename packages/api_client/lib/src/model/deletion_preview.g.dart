// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletionPreview _$DeletionPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeletionPreview',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['outstandingReceivablesPaise', 'vendor'],
        );
        final val = DeletionPreview(
          outstandingReceivablesPaise: $checkedConvert(
              'outstandingReceivablesPaise', (v) => v as String),
          vendor: $checkedConvert('vendor', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$DeletionPreviewToJson(DeletionPreview instance) =>
    <String, dynamic>{
      'outstandingReceivablesPaise': instance.outstandingReceivablesPaise,
      'vendor': instance.vendor,
    };
