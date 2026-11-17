//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'khata_ledger_entry.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KhataLedgerEntry {
  /// Returns a new [KhataLedgerEntry] instance.
  KhataLedgerEntry({
    required this.id,
    required this.vendorCustomerId,
    required this.type,
    required this.amountPaise,
    required this.entryDate,
    required this.refType,
    required this.refId,
    required this.reversesEntryId,
    required this.note,
    required this.productSummary,
    required this.paymentStatus,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'vendorCustomerId',
    required: true,
    includeIfNull: false,
  )
  final String vendorCustomerId;

  @JsonKey(
    name: r'type',
    required: true,
    includeIfNull: false,
  )
  final KhataLedgerEntryTypeEnum type;

  @JsonKey(
    name: r'amountPaise',
    required: true,
    includeIfNull: false,
  )
  final String amountPaise;

  @JsonKey(
    name: r'entryDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime entryDate;

  @JsonKey(
    name: r'refType',
    required: true,
    includeIfNull: false,
  )
  final String refType;

  @JsonKey(
    name: r'refId',
    required: true,
    includeIfNull: false,
  )
  final String refId;

  @JsonKey(
    name: r'reversesEntryId',
    required: true,
    includeIfNull: true,
  )
  final String? reversesEntryId;

  @JsonKey(
    name: r'note',
    required: true,
    includeIfNull: false,
  )
  final String note;

  @JsonKey(
    name: r'productSummary',
    required: true,
    includeIfNull: true,
  )
  final String? productSummary;

  /// Persisted source state only, no invented allocation of standalone payments/claims.
  @JsonKey(
    name: r'paymentStatus',
    required: true,
    includeIfNull: true,
  )
  final String? paymentStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhataLedgerEntry &&
          other.id == id &&
          other.vendorCustomerId == vendorCustomerId &&
          other.type == type &&
          other.amountPaise == amountPaise &&
          other.entryDate == entryDate &&
          other.refType == refType &&
          other.refId == refId &&
          other.reversesEntryId == reversesEntryId &&
          other.note == note &&
          other.productSummary == productSummary &&
          other.paymentStatus == paymentStatus;

  @override
  int get hashCode =>
      id.hashCode +
      vendorCustomerId.hashCode +
      type.hashCode +
      amountPaise.hashCode +
      entryDate.hashCode +
      refType.hashCode +
      refId.hashCode +
      (reversesEntryId == null ? 0 : reversesEntryId.hashCode) +
      note.hashCode +
      (productSummary == null ? 0 : productSummary.hashCode) +
      (paymentStatus == null ? 0 : paymentStatus.hashCode);

  factory KhataLedgerEntry.fromJson(Map<String, dynamic> json) =>
      _$KhataLedgerEntryFromJson(json);

  Map<String, dynamic> toJson() => _$KhataLedgerEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum KhataLedgerEntryTypeEnum {
  @JsonValue(r'DEBIT')
  DEBIT(r'DEBIT'),
  @JsonValue(r'CREDIT')
  CREDIT(r'CREDIT');

  const KhataLedgerEntryTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
