//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'device_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceDto {
  /// Returns a new [DeviceDto] instance.
  DeviceDto({

    required  this.platform,

     this.appVersion,

     this.osVersion,
  });

  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final DeviceDtoPlatformEnum platform;



  @JsonKey(
    
    name: r'appVersion',
    required: false,
    includeIfNull: false,
  )


  final String? appVersion;



  @JsonKey(
    
    name: r'osVersion',
    required: false,
    includeIfNull: false,
  )


  final String? osVersion;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceDto &&
      other.platform == platform &&
      other.appVersion == appVersion &&
      other.osVersion == osVersion;

    @override
    int get hashCode =>
        platform.hashCode +
        appVersion.hashCode +
        osVersion.hashCode;

  factory DeviceDto.fromJson(Map<String, dynamic> json) => _$DeviceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum DeviceDtoPlatformEnum {
@JsonValue(r'ANDROID')
ANDROID(r'ANDROID'),
@JsonValue(r'IOS')
IOS(r'IOS'),
@JsonValue(r'WEB')
WEB(r'WEB');

const DeviceDtoPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


