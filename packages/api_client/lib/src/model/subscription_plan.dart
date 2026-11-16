//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_plan.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionPlan {
  /// Returns a new [SubscriptionPlan] instance.
  SubscriptionPlan({
    required this.productId,
    required this.productName,
    required this.kind,
    required this.qty,
    required this.dailyAmountPaise,
    required this.monthlyEstimatePaise,
    required this.mostPopular,
  });

  @JsonKey(
    name: r'productId',
    required: true,
    includeIfNull: false,
  )
  final String productId;

  @JsonKey(
    name: r'productName',
    required: true,
    includeIfNull: false,
  )
  final String productName;

  /// CUSTOM or an available 500/1000/2000 ml daily size.
  @JsonKey(
    name: r'kind',
    required: true,
    includeIfNull: false,
  )
  final String kind;

  @JsonKey(
    name: r'qty',
    required: true,
    includeIfNull: false,
  )
  final int qty;

  @JsonKey(
    name: r'dailyAmountPaise',
    required: true,
    includeIfNull: false,
  )
  final String dailyAmountPaise;

  @JsonKey(
    name: r'monthlyEstimatePaise',
    required: true,
    includeIfNull: false,
  )
  final String monthlyEstimatePaise;

  /// Unavailable until vendor selection is configured; never guessed.
  @JsonKey(
    name: r'mostPopular',
    required: true,
    includeIfNull: true,
  )
  final bool? mostPopular;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          other.productId == productId &&
          other.productName == productName &&
          other.kind == kind &&
          other.qty == qty &&
          other.dailyAmountPaise == dailyAmountPaise &&
          other.monthlyEstimatePaise == monthlyEstimatePaise &&
          other.mostPopular == mostPopular;

  @override
  int get hashCode =>
      productId.hashCode +
      productName.hashCode +
      kind.hashCode +
      qty.hashCode +
      dailyAmountPaise.hashCode +
      monthlyEstimatePaise.hashCode +
      (mostPopular == null ? 0 : mostPopular.hashCode);

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPlanToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
