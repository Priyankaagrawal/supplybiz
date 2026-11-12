//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/home_category.dart';
import 'package:supplybiz_api_client/src/model/home_delivery.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_home.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerHome {
  /// Returns a new [CustomerHome] instance.
  CustomerHome({
    required this.serverTime,
    required this.businessDate,
    required this.categories,
    required this.deliveries,
    required this.nextCursor,
  });

  @JsonKey(
    name: r'serverTime',
    required: true,
    includeIfNull: false,
  )
  final DateTime serverTime;

  /// Database-derived Asia/Kolkata date.
  @JsonKey(
    name: r'businessDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime businessDate;

  @JsonKey(
    name: r'categories',
    required: true,
    includeIfNull: false,
  )
  final List<HomeCategory> categories;

  @JsonKey(
    name: r'deliveries',
    required: true,
    includeIfNull: false,
  )
  final List<HomeDelivery> deliveries;

  @JsonKey(
    name: r'nextCursor',
    required: true,
    includeIfNull: true,
  )
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerHome &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.categories == categories &&
          other.deliveries == deliveries &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      serverTime.hashCode +
      businessDate.hashCode +
      categories.hashCode +
      deliveries.hashCode +
      (nextCursor == null ? 0 : nextCursor.hashCode);

  factory CustomerHome.fromJson(Map<String, dynamic> json) =>
      _$CustomerHomeFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerHomeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
