//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/device_dto.dart';
import 'package:supplybiz_api_client/src/model/consent_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verify_otp_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerifyOtpDto {
  /// Returns a new [VerifyOtpDto] instance.
  VerifyOtpDto({

    required  this.mobile,

    required  this.code,

    required  this.device,

     this.consent,
  });

  @JsonKey(
    
    name: r'mobile',
    required: true,
    includeIfNull: false,
  )


  final String mobile;



  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'device',
    required: true,
    includeIfNull: false,
  )


  final DeviceDto device;



  @JsonKey(
    
    name: r'consent',
    required: false,
    includeIfNull: false,
  )


  final ConsentDto? consent;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VerifyOtpDto &&
      other.mobile == mobile &&
      other.code == code &&
      other.device == device &&
      other.consent == consent;

    @override
    int get hashCode =>
        mobile.hashCode +
        code.hashCode +
        device.hashCode +
        consent.hashCode;

  factory VerifyOtpDto.fromJson(Map<String, dynamic> json) => _$VerifyOtpDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyOtpDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

