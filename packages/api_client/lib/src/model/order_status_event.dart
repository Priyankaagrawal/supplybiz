//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'order_status_event.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderStatusEvent {
  /// Returns a new [OrderStatusEvent] instance.
  OrderStatusEvent({
    required this.status,
    required this.reason,
    required this.at,
  });

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: true,
  )
  final String? reason;

  @JsonKey(
    name: r'at',
    required: true,
    includeIfNull: false,
  )
  final String at;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderStatusEvent &&
          other.status == status &&
          other.reason == reason &&
          other.at == at;

  @override
  int get hashCode =>
      status.hashCode + (reason == null ? 0 : reason.hashCode) + at.hashCode;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusEventFromJson(json);

  Map<String, dynamic> toJson() => _$OrderStatusEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
