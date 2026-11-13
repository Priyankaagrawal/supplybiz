//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'delivery_payment_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeliveryPaymentInput {
  /// Returns a new [DeliveryPaymentInput] instance.
  DeliveryPaymentInput({
    required this.collected,
    this.method,
    this.amountPaise,
  });

  @JsonKey(
    name: r'collected',
    required: true,
    includeIfNull: false,
  )
  final bool collected;

  /// Off-platform record only; no platform wallet or money movement.
  @JsonKey(
    name: r'method',
    required: false,
    includeIfNull: false,
  )
  final DeliveryPaymentInputMethodEnum? method;

  /// Exact positive integer paise, decimal string. Required when collected=true.
  @JsonKey(
    name: r'amountPaise',
    required: false,
    includeIfNull: false,
  )
  final String? amountPaise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryPaymentInput &&
          other.collected == collected &&
          other.method == method &&
          other.amountPaise == amountPaise;

  @override
  int get hashCode =>
      collected.hashCode + method.hashCode + amountPaise.hashCode;

  factory DeliveryPaymentInput.fromJson(Map<String, dynamic> json) =>
      _$DeliveryPaymentInputFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryPaymentInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Off-platform record only; no platform wallet or money movement.
enum DeliveryPaymentInputMethodEnum {
  @JsonValue(r'CASH')
  CASH(r'CASH'),
  @JsonValue(r'UPI')
  UPI(r'UPI'),
  @JsonValue(r'BANK')
  BANK(r'BANK'),
  @JsonValue(r'WALLET')
  WALLET(r'WALLET');

  const DeliveryPaymentInputMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
