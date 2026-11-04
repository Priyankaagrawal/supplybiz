//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'send_otp_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SendOtpDto {
  /// Returns a new [SendOtpDto] instance.
  SendOtpDto({
    required this.mobile,
    this.channel,
    this.appHash,
  });

  @JsonKey(
    name: r'mobile',
    required: true,
    includeIfNull: false,
  )
  final String mobile;

  /// Defaults to SMS.
  @JsonKey(
    name: r'channel',
    required: false,
    includeIfNull: false,
  )
  final SendOtpDtoChannelEnum? channel;

  @JsonKey(
    name: r'appHash',
    required: false,
    includeIfNull: false,
  )
  final String? appHash;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendOtpDto &&
          other.mobile == mobile &&
          other.channel == channel &&
          other.appHash == appHash;

  @override
  int get hashCode => mobile.hashCode + channel.hashCode + appHash.hashCode;

  factory SendOtpDto.fromJson(Map<String, dynamic> json) =>
      _$SendOtpDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SendOtpDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Defaults to SMS.
enum SendOtpDtoChannelEnum {
  @JsonValue(r'SMS')
  SMS(r'SMS'),
  @JsonValue(r'WHATSAPP')
  WHATSAPP(r'WHATSAPP');

  const SendOtpDtoChannelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
