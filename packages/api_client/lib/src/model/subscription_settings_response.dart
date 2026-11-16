//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/subscription_settings_summary.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_settings_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionSettingsResponse {
  /// Returns a new [SubscriptionSettingsResponse] instance.
  SubscriptionSettingsResponse({
    required this.version,
    required this.serverTime,
    required this.businessDate,
    required this.autoAcceptSubscriptions,
    required this.effectiveAutoAcceptSubscriptions,
    required this.canAutoAccept,
    required this.canEditSubscriptions,
    required this.canReduceActivity,
    required this.deliveryAvailable,
    required this.deliveryStartTime,
    required this.deliveryEndTime,
    required this.maxDailyOrders,
    required this.dailyMilkCapacityLitres,
    required this.pauseAllSubscriptions,
    required this.summary,
  });

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

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

  @JsonKey(
    name: r'autoAcceptSubscriptions',
    required: true,
    includeIfNull: false,
  )
  final bool autoAcceptSubscriptions;

  @JsonKey(
    name: r'effectiveAutoAcceptSubscriptions',
    required: true,
    includeIfNull: false,
  )
  final bool effectiveAutoAcceptSubscriptions;

  @JsonKey(
    name: r'canAutoAccept',
    required: true,
    includeIfNull: false,
  )
  final bool canAutoAccept;

  @JsonKey(
    name: r'canEditSubscriptions',
    required: true,
    includeIfNull: false,
  )
  final bool canEditSubscriptions;

  /// Owned reducing controls remain available with history access after expiry/downgrade.
  @JsonKey(
    name: r'canReduceActivity',
    required: true,
    includeIfNull: false,
  )
  final bool canReduceActivity;

  @JsonKey(
    name: r'deliveryAvailable',
    required: true,
    includeIfNull: false,
  )
  final bool deliveryAvailable;

  @JsonKey(
    name: r'deliveryStartTime',
    required: true,
    includeIfNull: true,
  )
  final String? deliveryStartTime;

  @JsonKey(
    name: r'deliveryEndTime',
    required: true,
    includeIfNull: true,
  )
  final String? deliveryEndTime;

  @JsonKey(
    name: r'maxDailyOrders',
    required: true,
    includeIfNull: true,
  )
  final int? maxDailyOrders;

  @JsonKey(
    name: r'dailyMilkCapacityLitres',
    required: true,
    includeIfNull: true,
  )
  final String? dailyMilkCapacityLitres;

  @JsonKey(
    name: r'pauseAllSubscriptions',
    required: true,
    includeIfNull: false,
  )
  final bool pauseAllSubscriptions;

  @JsonKey(
    name: r'summary',
    required: true,
    includeIfNull: false,
  )
  final SubscriptionSettingsSummary summary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSettingsResponse &&
          other.version == version &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.autoAcceptSubscriptions == autoAcceptSubscriptions &&
          other.effectiveAutoAcceptSubscriptions ==
              effectiveAutoAcceptSubscriptions &&
          other.canAutoAccept == canAutoAccept &&
          other.canEditSubscriptions == canEditSubscriptions &&
          other.canReduceActivity == canReduceActivity &&
          other.deliveryAvailable == deliveryAvailable &&
          other.deliveryStartTime == deliveryStartTime &&
          other.deliveryEndTime == deliveryEndTime &&
          other.maxDailyOrders == maxDailyOrders &&
          other.dailyMilkCapacityLitres == dailyMilkCapacityLitres &&
          other.pauseAllSubscriptions == pauseAllSubscriptions &&
          other.summary == summary;

  @override
  int get hashCode =>
      version.hashCode +
      serverTime.hashCode +
      businessDate.hashCode +
      autoAcceptSubscriptions.hashCode +
      effectiveAutoAcceptSubscriptions.hashCode +
      canAutoAccept.hashCode +
      canEditSubscriptions.hashCode +
      canReduceActivity.hashCode +
      deliveryAvailable.hashCode +
      (deliveryStartTime == null ? 0 : deliveryStartTime.hashCode) +
      (deliveryEndTime == null ? 0 : deliveryEndTime.hashCode) +
      (maxDailyOrders == null ? 0 : maxDailyOrders.hashCode) +
      (dailyMilkCapacityLitres == null ? 0 : dailyMilkCapacityLitres.hashCode) +
      pauseAllSubscriptions.hashCode +
      summary.hashCode;

  factory SubscriptionSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSettingsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionSettingsResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
