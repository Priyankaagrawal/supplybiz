//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/vendor_khata_account.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_khata_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorKhataList {
  /// Returns a new [VendorKhataList] instance.
  VendorKhataList({
    required this.items,
    required this.total,
    required this.totalReceivablePaise,
    required this.thisMonthReceivedPaise,
    required this.canAdjust,
    required this.canRecordPayment,
    required this.serverTime,
    required this.businessDate,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<VendorKhataAccount> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @JsonKey(
    name: r'totalReceivablePaise',
    required: true,
    includeIfNull: false,
  )
  final String totalReceivablePaise;

  @JsonKey(
    name: r'thisMonthReceivedPaise',
    required: true,
    includeIfNull: false,
  )
  final String thisMonthReceivedPaise;

  @JsonKey(
    name: r'canAdjust',
    required: true,
    includeIfNull: false,
  )
  final bool canAdjust;

  @JsonKey(
    name: r'canRecordPayment',
    required: true,
    includeIfNull: false,
  )
  final bool canRecordPayment;

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
  final String businessDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorKhataList &&
          other.items == items &&
          other.total == total &&
          other.totalReceivablePaise == totalReceivablePaise &&
          other.thisMonthReceivedPaise == thisMonthReceivedPaise &&
          other.canAdjust == canAdjust &&
          other.canRecordPayment == canRecordPayment &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate;

  @override
  int get hashCode =>
      items.hashCode +
      total.hashCode +
      totalReceivablePaise.hashCode +
      thisMonthReceivedPaise.hashCode +
      canAdjust.hashCode +
      canRecordPayment.hashCode +
      serverTime.hashCode +
      businessDate.hashCode;

  factory VendorKhataList.fromJson(Map<String, dynamic> json) =>
      _$VendorKhataListFromJson(json);

  Map<String, dynamic> toJson() => _$VendorKhataListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
