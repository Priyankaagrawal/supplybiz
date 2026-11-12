// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteResult _$FavoriteResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'FavoriteResult',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['vendorId', 'favorite'],
        );
        final val = FavoriteResult(
          vendorId: $checkedConvert('vendorId', (v) => v as String),
          favorite: $checkedConvert('favorite', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$FavoriteResultToJson(FavoriteResult instance) =>
    <String, dynamic>{
      'vendorId': instance.vendorId,
      'favorite': instance.favorite,
    };
