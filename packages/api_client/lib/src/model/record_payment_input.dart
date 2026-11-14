//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'record_payment_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecordPaymentInput {
  /// Returns a new [RecordPaymentInput] instance.
  RecordPaymentInput({
    required this.vendorCustomerId,
    required this.amountPaise,
    required this.method,
    required this.receivedOn,
    this.note,
  });

  @JsonKey(
    name: r'vendorCustomerId',
    required: true,
    includeIfNull: false,
  )
  final String vendorCustomerId;

  /// Positive exact integer paise as decimal string, signed BIGINT maximum.
  @JsonKey(
    name: r'amountPaise',
    required: true,
    includeIfNull: false,
  )
  final String amountPaise;

  /// External payment record only; no platform money movement.
  @JsonKey(
    name: r'method',
    required: true,
    includeIfNull: false,
  )
  final RecordPaymentInputMethodEnum method;

  /// Received business date, YYYY-MM-DD.
  @JsonKey(
    name: r'receivedOn',
    required: true,
    includeIfNull: false,
  )
  final DateTime receivedOn;

  @JsonKey(
    name: r'note',
    required: false,
    includeIfNull: false,
  )
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordPaymentInput &&
          other.vendorCustomerId == vendorCustomerId &&
          other.amountPaise == amountPaise &&
          other.method == method &&
          other.receivedOn == receivedOn &&
          other.note == note;

  @override
  int get hashCode =>
      vendorCustomerId.hashCode +
      amountPaise.hashCode +
      method.hashCode +
      receivedOn.hashCode +
      note.hashCode;

  factory RecordPaymentInput.fromJson(Map<String, dynamic> json) =>
      _$RecordPaymentInputFromJson(json);

  Map<String, dynamic> toJson() => _$RecordPaymentInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// External payment record only; no platform money movement.
enum RecordPaymentInputMethodEnum {
  @JsonValue(r'CASH')
  CASH(r'CASH'),
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'BANK')
  BANK(r'BANK'),
  @JsonValue(r'WALLET')
  WALLET(r'WALLET');

  const RecordPaymentInputMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
