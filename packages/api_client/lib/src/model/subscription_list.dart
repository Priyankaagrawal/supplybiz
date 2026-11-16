//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/subscription_record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionList {
  /// Returns a new [SubscriptionList] instance.
  SubscriptionList({
    required this.serverTime,
    required this.businessDate,
    required this.items,
    required this.total,
  });

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
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<SubscriptionRecord> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionList &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.items == items &&
          other.total == total;

  @override
  int get hashCode =>
      serverTime.hashCode +
      businessDate.hashCode +
      items.hashCode +
      total.hashCode;

  factory SubscriptionList.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionListFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
