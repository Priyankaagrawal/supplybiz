//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/holiday_record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'holiday_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HolidayList {
  /// Returns a new [HolidayList] instance.
  HolidayList({
    required this.items,
    required this.total,
    required this.serverTime,
    required this.businessDate,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<HolidayRecord> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final String serverTime;

  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HolidayList &&
          other.items == items &&
          other.total == total &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate;

  @override
  int get hashCode =>
      items.hashCode +
      total.hashCode +
      serverTime.hashCode +
      businessDate.hashCode;

  factory HolidayList.fromJson(Map<String, dynamic> json) =>
      _$HolidayListFromJson(json);

  Map<String, dynamic> toJson() => _$HolidayListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
