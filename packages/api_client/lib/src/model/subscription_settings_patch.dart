//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_settings_patch.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionSettingsPatch {
  /// Returns a new [SubscriptionSettingsPatch] instance.
  SubscriptionSettingsPatch({
    required this.version,
    this.autoAcceptSubscriptions,
    this.deliveryAvailable,
    this.deliveryStartTime,
    this.deliveryEndTime,
    this.maxDailyOrders,
    this.dailyMilkCapacityLitres,
    this.pauseAllSubscriptions,
    this.clearDeliveryWindow,
    this.clearMaxDailyOrders,
    this.clearDailyMilkCapacity,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  /// Enabling requires active BUSINESS+.
  @JsonKey(
    name: r'autoAcceptSubscriptions',
    required: false,
    includeIfNull: false,
  )
  final bool? autoAcceptSubscriptions;

  @JsonKey(
    name: r'deliveryAvailable',
    required: false,
    includeIfNull: false,
  )
  final bool? deliveryAvailable;

  /// IST daily delivery window. Both ends may be cleared with null; overnight windows are allowed.
  @JsonKey(
    name: r'deliveryStartTime',
    required: false,
    includeIfNull: false,
  )
  final String? deliveryStartTime;

  @JsonKey(
    name: r'deliveryEndTime',
    required: false,
    includeIfNull: false,
  )
  final String? deliveryEndTime;

  /// Positive order limit; null is unlimited. Typed clients may use clearMaxDailyOrders.
  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'maxDailyOrders',
    required: false,
    includeIfNull: false,
  )
  final int? maxDailyOrders;

  /// Positive exact litres, up to three fractional digits (1 ml), max 2147483.647. Null is unlimited. Typed clients may use clearDailyMilkCapacity.
  @JsonKey(
    name: r'dailyMilkCapacityLitres',
    required: false,
    includeIfNull: false,
  )
  final String? dailyMilkCapacityLitres;

  @JsonKey(
    name: r'pauseAllSubscriptions',
    required: false,
    includeIfNull: false,
  )
  final bool? pauseAllSubscriptions;

  /// Set true to clear both delivery times. Cannot accompany non-null times.
  @JsonKey(
    name: r'clearDeliveryWindow',
    required: false,
    includeIfNull: false,
  )
  final bool? clearDeliveryWindow;

  /// Set true to remove the order limit. Cannot accompany a non-null limit.
  @JsonKey(
    name: r'clearMaxDailyOrders',
    required: false,
    includeIfNull: false,
  )
  final bool? clearMaxDailyOrders;

  /// Set true to remove the milk limit. Cannot accompany a non-null limit.
  @JsonKey(
    name: r'clearDailyMilkCapacity',
    required: false,
    includeIfNull: false,
  )
  final bool? clearDailyMilkCapacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSettingsPatch &&
          other.version == version &&
          other.autoAcceptSubscriptions == autoAcceptSubscriptions &&
          other.deliveryAvailable == deliveryAvailable &&
          other.deliveryStartTime == deliveryStartTime &&
          other.deliveryEndTime == deliveryEndTime &&
          other.maxDailyOrders == maxDailyOrders &&
          other.dailyMilkCapacityLitres == dailyMilkCapacityLitres &&
          other.pauseAllSubscriptions == pauseAllSubscriptions &&
          other.clearDeliveryWindow == clearDeliveryWindow &&
          other.clearMaxDailyOrders == clearMaxDailyOrders &&
          other.clearDailyMilkCapacity == clearDailyMilkCapacity;

  @override
  int get hashCode =>
      version.hashCode +
      autoAcceptSubscriptions.hashCode +
      deliveryAvailable.hashCode +
      (deliveryStartTime == null ? 0 : deliveryStartTime.hashCode) +
      (deliveryEndTime == null ? 0 : deliveryEndTime.hashCode) +
      (maxDailyOrders == null ? 0 : maxDailyOrders.hashCode) +
      (dailyMilkCapacityLitres == null ? 0 : dailyMilkCapacityLitres.hashCode) +
      pauseAllSubscriptions.hashCode +
      clearDeliveryWindow.hashCode +
      clearMaxDailyOrders.hashCode +
      clearDailyMilkCapacity.hashCode;

  factory SubscriptionSettingsPatch.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSettingsPatchFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionSettingsPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
