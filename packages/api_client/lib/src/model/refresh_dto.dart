//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'refresh_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RefreshDto {
  /// Returns a new [RefreshDto] instance.
  RefreshDto({

    required  this.refreshToken,
  });

  @JsonKey(
    
    name: r'refreshToken',
    required: true,
    includeIfNull: false,
  )


  final String refreshToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RefreshDto &&
      other.refreshToken == refreshToken;

    @override
    int get hashCode =>
        refreshToken.hashCode;

  factory RefreshDto.fromJson(Map<String, dynamic> json) => _$RefreshDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

