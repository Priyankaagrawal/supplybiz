//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_settings_summary.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionSettingsSummary {
  /// Returns a new [SubscriptionSettingsSummary] instance.
  SubscriptionSettingsSummary({
    required this.totalSubscriptions,
    required this.active,
    required this.paused,
    required this.pendingApproval,
    required this.cancelled,
    required this.rejected,
    required this.completed,
    required this.subscriptionCustomers,
  });

  @JsonKey(
    name: r'totalSubscriptions',
    required: true,
    includeIfNull: false,
  )
  final int totalSubscriptions;

  @JsonKey(
    name: r'active',
    required: true,
    includeIfNull: false,
  )
  final int active;

  @JsonKey(
    name: r'paused',
    required: true,
    includeIfNull: false,
  )
  final int paused;

  @JsonKey(
    name: r'pendingApproval',
    required: true,
    includeIfNull: false,
  )
  final int pendingApproval;

  @JsonKey(
    name: r'cancelled',
    required: true,
    includeIfNull: false,
  )
  final int cancelled;

  @JsonKey(
    name: r'rejected',
    required: true,
    includeIfNull: false,
  )
  final int rejected;

  @JsonKey(
    name: r'completed',
    required: true,
    includeIfNull: false,
  )
  final int completed;

  /// Distinct undeleted vendor customers with ACTIVE/PAUSED subscriptions.
  @JsonKey(
    name: r'subscriptionCustomers',
    required: true,
    includeIfNull: false,
  )
  final int subscriptionCustomers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSettingsSummary &&
          other.totalSubscriptions == totalSubscriptions &&
          other.active == active &&
          other.paused == paused &&
          other.pendingApproval == pendingApproval &&
          other.cancelled == cancelled &&
          other.rejected == rejected &&
          other.completed == completed &&
          other.subscriptionCustomers == subscriptionCustomers;

  @override
  int get hashCode =>
      totalSubscriptions.hashCode +
      active.hashCode +
      paused.hashCode +
      pendingApproval.hashCode +
      cancelled.hashCode +
      rejected.hashCode +
      completed.hashCode +
      subscriptionCustomers.hashCode;

  factory SubscriptionSettingsSummary.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSettingsSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionSettingsSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
