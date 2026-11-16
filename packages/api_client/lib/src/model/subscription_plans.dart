//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/subscription_plan.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_plans.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionPlans {
  /// Returns a new [SubscriptionPlans] instance.
  SubscriptionPlans({
    required this.items,
    required this.timeSlots,
    required this.freeDelivery,
    required this.earliestStartDate,
    required this.estimateMonth,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<SubscriptionPlan> items;

  @JsonKey(
    name: r'timeSlots',
    required: true,
    includeIfNull: false,
  )
  final List<String> timeSlots;

  @JsonKey(
    name: r'freeDelivery',
    required: true,
    includeIfNull: false,
  )
  final bool freeDelivery;

  @JsonKey(
    name: r'earliestStartDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime earliestStartDate;

  @JsonKey(
    name: r'estimateMonth',
    required: true,
    includeIfNull: false,
  )
  final String estimateMonth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlans &&
          other.items == items &&
          other.timeSlots == timeSlots &&
          other.freeDelivery == freeDelivery &&
          other.earliestStartDate == earliestStartDate &&
          other.estimateMonth == estimateMonth;

  @override
  int get hashCode =>
      items.hashCode +
      timeSlots.hashCode +
      freeDelivery.hashCode +
      earliestStartDate.hashCode +
      estimateMonth.hashCode;

  factory SubscriptionPlans.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlansFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPlansToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
