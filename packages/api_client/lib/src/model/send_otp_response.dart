//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'send_otp_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SendOtpResponse {
  /// Returns a new [SendOtpResponse] instance.
  SendOtpResponse({
    required this.resendAfterSec,
    required this.expiresInSec,
  });

  // minimum: 30
  // maximum: 30
  @JsonKey(
    name: r'resendAfterSec',
    required: true,
    includeIfNull: false,
  )
  final int resendAfterSec;

  // minimum: 300
  // maximum: 300
  @JsonKey(
    name: r'expiresInSec',
    required: true,
    includeIfNull: false,
  )
  final int expiresInSec;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendOtpResponse &&
          other.resendAfterSec == resendAfterSec &&
          other.expiresInSec == expiresInSec;

  @override
  int get hashCode => resendAfterSec.hashCode + expiresInSec.hashCode;

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$SendOtpResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendOtpResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
