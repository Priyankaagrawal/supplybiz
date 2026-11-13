//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'order_transition_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderTransitionInput {
  /// Returns a new [OrderTransitionInput] instance.
  OrderTransitionInput({
    required this.to,
    required this.version,
    this.reason,
    this.reasonText,
  });

  @JsonKey(
    name: r'to',
    required: true,
    includeIfNull: false,
  )
  final OrderTransitionInputToEnum to;

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'reason',
    required: false,
    includeIfNull: false,
  )
  final OrderTransitionInputReasonEnum? reason;

  /// Required for OTHER; 5–200 characters.
  @JsonKey(
    name: r'reasonText',
    required: false,
    includeIfNull: false,
  )
  final String? reasonText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderTransitionInput &&
          other.to == to &&
          other.version == version &&
          other.reason == reason &&
          other.reasonText == reasonText;

  @override
  int get hashCode =>
      to.hashCode + version.hashCode + reason.hashCode + reasonText.hashCode;

  factory OrderTransitionInput.fromJson(Map<String, dynamic> json) =>
      _$OrderTransitionInputFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTransitionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum OrderTransitionInputToEnum {
  @JsonValue(r'ACCEPTED')
  ACCEPTED(r'ACCEPTED'),
  @JsonValue(r'REJECTED')
  REJECTED(r'REJECTED'),
  @JsonValue(r'PREPARING')
  PREPARING(r'PREPARING'),
  @JsonValue(r'OUT_FOR_DELIVERY')
  OUT_FOR_DELIVERY(r'OUT_FOR_DELIVERY');

  const OrderTransitionInputToEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum OrderTransitionInputReasonEnum {
  @JsonValue(r'CUSTOMER_UNAVAILABLE')
  CUSTOMER_UNAVAILABLE(r'CUSTOMER_UNAVAILABLE'),
  @JsonValue(r'OUT_OF_STOCK')
  OUT_OF_STOCK(r'OUT_OF_STOCK'),
  @JsonValue(r'NOT_SERVICEABLE')
  NOT_SERVICEABLE(r'NOT_SERVICEABLE'),
  @JsonValue(r'CUSTOMER_REQUEST')
  CUSTOMER_REQUEST(r'CUSTOMER_REQUEST'),
  @JsonValue(r'OTHER')
  OTHER(r'OTHER');

  const OrderTransitionInputReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
