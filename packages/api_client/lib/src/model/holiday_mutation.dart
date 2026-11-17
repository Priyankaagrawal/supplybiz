//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/holiday_record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'holiday_mutation.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HolidayMutation {
  /// Returns a new [HolidayMutation] instance.
  HolidayMutation({
    required this.holiday,
    required this.cancelledOrders,
  });

  @JsonKey(
    name: r'holiday',
    required: true,
    includeIfNull: false,
  )
  final HolidayRecord holiday;

  @JsonKey(
    name: r'cancelledOrders',
    required: true,
    includeIfNull: false,
  )
  final int cancelledOrders;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HolidayMutation &&
          other.holiday == holiday &&
          other.cancelledOrders == cancelledOrders;

  @override
  int get hashCode => holiday.hashCode + cancelledOrders.hashCode;

  factory HolidayMutation.fromJson(Map<String, dynamic> json) =>
      _$HolidayMutationFromJson(json);

  Map<String, dynamic> toJson() => _$HolidayMutationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
