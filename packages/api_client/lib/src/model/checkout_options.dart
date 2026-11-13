//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'checkout_options.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckoutOptions {
  /// Returns a new [CheckoutOptions] instance.
  CheckoutOptions({
    required this.serverTime,
    required this.businessDate,
    required this.availableDates,
    required this.timeSlots,
    required this.sameDayCutoff,
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
  final String businessDate;

  @JsonKey(
    name: r'availableDates',
    required: true,
    includeIfNull: false,
  )
  final List<String> availableDates;

  @JsonKey(
    name: r'timeSlots',
    required: true,
    includeIfNull: false,
  )
  final List<String> timeSlots;

  @JsonKey(
    name: r'sameDayCutoff',
    required: true,
    includeIfNull: true,
  )
  final String? sameDayCutoff;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutOptions &&
          other.serverTime == serverTime &&
          other.businessDate == businessDate &&
          other.availableDates == availableDates &&
          other.timeSlots == timeSlots &&
          other.sameDayCutoff == sameDayCutoff;

  @override
  int get hashCode =>
      serverTime.hashCode +
      businessDate.hashCode +
      availableDates.hashCode +
      timeSlots.hashCode +
      (sameDayCutoff == null ? 0 : sameDayCutoff.hashCode);

  factory CheckoutOptions.fromJson(Map<String, dynamic> json) =>
      _$CheckoutOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$CheckoutOptionsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
