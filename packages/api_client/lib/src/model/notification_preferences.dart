//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NotificationPreferences {
  /// Returns a new [NotificationPreferences] instance.
  NotificationPreferences({
    required this.orders,
    required this.payments,
    required this.delivery,
    required this.system,
  });

  @JsonKey(
    name: r'orders',
    required: true,
    includeIfNull: false,
  )
  final bool orders;

  @JsonKey(
    name: r'payments',
    required: true,
    includeIfNull: false,
  )
  final bool payments;

  @JsonKey(
    name: r'delivery',
    required: true,
    includeIfNull: false,
  )
  final bool delivery;

  /// Optional system pushes only; security/KYC always bypass this preference.
  @JsonKey(
    name: r'system',
    required: true,
    includeIfNull: false,
  )
  final bool system;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          other.orders == orders &&
          other.payments == payments &&
          other.delivery == delivery &&
          other.system == system;

  @override
  int get hashCode =>
      orders.hashCode + payments.hashCode + delivery.hashCode + system.hashCode;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
