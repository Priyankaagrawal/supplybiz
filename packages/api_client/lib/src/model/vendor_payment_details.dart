//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_payment_details.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorPaymentDetails {
  /// Returns a new [VendorPaymentDetails] instance.
  VendorPaymentDetails({
    required this.version,
    required this.published,
    required this.upiId,
    required this.payeeName,
  });

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'published',
    required: true,
    includeIfNull: false,
  )
  final bool published;

  @JsonKey(
    name: r'upiId',
    required: true,
    includeIfNull: true,
  )
  final String? upiId;

  @JsonKey(
    name: r'payeeName',
    required: true,
    includeIfNull: false,
  )
  final String payeeName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorPaymentDetails &&
          other.version == version &&
          other.published == published &&
          other.upiId == upiId &&
          other.payeeName == payeeName;

  @override
  int get hashCode =>
      version.hashCode +
      published.hashCode +
      (upiId == null ? 0 : upiId.hashCode) +
      payeeName.hashCode;

  factory VendorPaymentDetails.fromJson(Map<String, dynamic> json) =>
      _$VendorPaymentDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$VendorPaymentDetailsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
