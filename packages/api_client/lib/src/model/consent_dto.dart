//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'consent_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConsentDto {
  /// Returns a new [ConsentDto] instance.
  ConsentDto({

    required  this.termsVersion,

    required  this.privacyVersion,
  });

  @JsonKey(
    
    name: r'termsVersion',
    required: true,
    includeIfNull: false,
  )


  final String termsVersion;



  @JsonKey(
    
    name: r'privacyVersion',
    required: true,
    includeIfNull: false,
  )


  final String privacyVersion;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConsentDto &&
      other.termsVersion == termsVersion &&
      other.privacyVersion == privacyVersion;

    @override
    int get hashCode =>
        termsVersion.hashCode +
        privacyVersion.hashCode;

  factory ConsentDto.fromJson(Map<String, dynamic> json) => _$ConsentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConsentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

