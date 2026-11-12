//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_about_holidays_inner.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorAboutHolidaysInner {
  /// Returns a new [VendorAboutHolidaysInner] instance.
  VendorAboutHolidaysInner({
    this.date,
    this.reason,
  });

  @JsonKey(
    name: r'date',
    required: false,
    includeIfNull: false,
  )
  final DateTime? date;

  @JsonKey(
    name: r'reason',
    required: false,
    includeIfNull: false,
  )
  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorAboutHolidaysInner &&
          other.date == date &&
          other.reason == reason;

  @override
  int get hashCode => date.hashCode + reason.hashCode;

  factory VendorAboutHolidaysInner.fromJson(Map<String, dynamic> json) =>
      _$VendorAboutHolidaysInnerFromJson(json);

  Map<String, dynamic> toJson() => _$VendorAboutHolidaysInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
