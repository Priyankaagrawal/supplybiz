//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'payment_claim_record.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentClaimRecord {
  /// Returns a new [PaymentClaimRecord] instance.
  PaymentClaimRecord({
    required this.id,
    required this.vendorId,
    required this.vendorCustomerId,
    required this.amountPaise,
    required this.method,
    required this.upiTxnRef,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.decidedAt,
    required this.rejectReason,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'vendorCustomerId',
    required: true,
    includeIfNull: false,
  )
  final String vendorCustomerId;

  @JsonKey(
    name: r'amountPaise',
    required: true,
    includeIfNull: false,
  )
  final String amountPaise;

  @JsonKey(
    name: r'method',
    required: true,
    includeIfNull: false,
  )
  final PaymentClaimRecordMethodEnum method;

  @JsonKey(
    name: r'upiTxnRef',
    required: true,
    includeIfNull: true,
  )
  final String? upiTxnRef;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final PaymentClaimRecordStatusEnum status;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )
  final String createdAt;

  @JsonKey(
    name: r'decidedAt',
    required: true,
    includeIfNull: true,
  )
  final String? decidedAt;

  @JsonKey(
    name: r'rejectReason',
    required: true,
    includeIfNull: true,
  )
  final String? rejectReason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentClaimRecord &&
          other.id == id &&
          other.vendorId == vendorId &&
          other.vendorCustomerId == vendorCustomerId &&
          other.amountPaise == amountPaise &&
          other.method == method &&
          other.upiTxnRef == upiTxnRef &&
          other.status == status &&
          other.version == version &&
          other.createdAt == createdAt &&
          other.decidedAt == decidedAt &&
          other.rejectReason == rejectReason;

  @override
  int get hashCode =>
      id.hashCode +
      vendorId.hashCode +
      vendorCustomerId.hashCode +
      amountPaise.hashCode +
      method.hashCode +
      (upiTxnRef == null ? 0 : upiTxnRef.hashCode) +
      status.hashCode +
      version.hashCode +
      createdAt.hashCode +
      (decidedAt == null ? 0 : decidedAt.hashCode) +
      (rejectReason == null ? 0 : rejectReason.hashCode);

  factory PaymentClaimRecord.fromJson(Map<String, dynamic> json) =>
      _$PaymentClaimRecordFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentClaimRecordToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PaymentClaimRecordMethodEnum {
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'CASH')
  CASH(r'CASH');

  const PaymentClaimRecordMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum PaymentClaimRecordStatusEnum {
  @JsonValue(r'PENDING')
  PENDING(r'PENDING'),
  @JsonValue(r'CONFIRMED')
  CONFIRMED(r'CONFIRMED'),
  @JsonValue(r'REJECTED')
  REJECTED(r'REJECTED');

  const PaymentClaimRecordStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
