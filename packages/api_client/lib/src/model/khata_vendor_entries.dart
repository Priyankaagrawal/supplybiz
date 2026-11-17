//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/khata_ledger_entry.dart';
import 'package:supplybiz_api_client/src/model/khata_billing_account.dart';
import 'package:json_annotation/json_annotation.dart';

part 'khata_vendor_entries.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KhataVendorEntries {
  /// Returns a new [KhataVendorEntries] instance.
  KhataVendorEntries({
    required this.vendorId,
    required this.vendorName,
    required this.month,
    required this.duePaise,
    required this.openingDuePaise,
    required this.closingDuePaise,
    required this.monthDebitPaise,
    required this.monthCreditPaise,
    required this.monthPaidPaise,
    required this.accounts,
    required this.items,
    required this.total,
    required this.serverTime,
    required this.businessDate,
  });

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'vendorName',
    required: true,
    includeIfNull: false,
  )
  final String vendorName;

  @JsonKey(
    name: r'month',
    required: true,
    includeIfNull: false,
  )
  final String month;

  @JsonKey(
    name: r'duePaise',
    required: true,
    includeIfNull: false,
  )
  final String duePaise;

  @JsonKey(
    name: r'openingDuePaise',
    required: true,
    includeIfNull: false,
  )
  final String openingDuePaise;

  @JsonKey(
    name: r'closingDuePaise',
    required: true,
    includeIfNull: false,
  )
  final String closingDuePaise;

  @JsonKey(
    name: r'monthDebitPaise',
    required: true,
    includeIfNull: false,
  )
  final String monthDebitPaise;

  @JsonKey(
    name: r'monthCreditPaise',
    required: true,
    includeIfNull: false,
  )
  final String monthCreditPaise;

  @JsonKey(
    name: r'monthPaidPaise',
    required: true,
    includeIfNull: false,
  )
  final String monthPaidPaise;

  @JsonKey(
    name: r'accounts',
    required: true,
    includeIfNull: false,
  )
  final List<KhataBillingAccount> accounts;

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<KhataLedgerEntry> items;

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
      other is KhataVendorEntries &&
          other.vendorId == vendorId &&
          other.vendorName == vendorName &&
          other.month == month &&
          other.duePaise == duePaise &&
          other.openingDuePaise == openingDuePaise &&
          other.closingDuePaise == closingDuePaise &&
          other.monthDebitPaise == monthDebitPaise &&
          other.monthCreditPaise == monthCreditPaise &&
          other.monthPaidPaise == monthPaidPaise &&
          other.accounts == accounts &&
          other.items == items &&
          other.total == total &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate;

  @override
  int get hashCode =>
      vendorId.hashCode +
      vendorName.hashCode +
      month.hashCode +
      duePaise.hashCode +
      openingDuePaise.hashCode +
      closingDuePaise.hashCode +
      monthDebitPaise.hashCode +
      monthCreditPaise.hashCode +
      monthPaidPaise.hashCode +
      accounts.hashCode +
      items.hashCode +
      total.hashCode +
      serverTime.hashCode +
      businessDate.hashCode;

  factory KhataVendorEntries.fromJson(Map<String, dynamic> json) =>
      _$KhataVendorEntriesFromJson(json);

  Map<String, dynamic> toJson() => _$KhataVendorEntriesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
