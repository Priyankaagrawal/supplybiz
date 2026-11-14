//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'payment_record.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentRecord {
  /// Returns a new [PaymentRecord] instance.
  PaymentRecord({
    required this.id,
    required this.vendorCustomerId,
    required this.orderId,
    required this.amountPaise,
    required this.method,
    required this.receivedOn,
    required this.note,
    required this.createdAt,
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
    name: r'orderId',
    required: true,
    includeIfNull: true,
  )
  final String? orderId;

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
  final String method;

  @JsonKey(
    name: r'receivedOn',
    required: true,
    includeIfNull: false,
  )
  final DateTime receivedOn;

  @JsonKey(
    name: r'note',
    required: true,
    includeIfNull: false,
  )
  final String note;

  @JsonKey(
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )
  final String createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentRecord &&
          other.id == id &&
          other.vendorCustomerId == vendorCustomerId &&
          other.orderId == orderId &&
          other.amountPaise == amountPaise &&
          other.method == method &&
          other.receivedOn == receivedOn &&
          other.note == note &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      vendorCustomerId.hashCode +
      (orderId == null ? 0 : orderId.hashCode) +
      amountPaise.hashCode +
      method.hashCode +
      receivedOn.hashCode +
      note.hashCode +
      createdAt.hashCode;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) =>
      _$PaymentRecordFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentRecordToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
