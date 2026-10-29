//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/me_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tokens_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TokensResponse {
  /// Returns a new [TokensResponse] instance.
  TokensResponse({

    required  this.accessToken,

    required  this.refreshToken,

    required  this.expiresInSec,

    required  this.user,
  });

  @JsonKey(
    
    name: r'accessToken',
    required: true,
    includeIfNull: false,
  )


  final String accessToken;



  @JsonKey(
    
    name: r'refreshToken',
    required: true,
    includeIfNull: false,
  )


  final String refreshToken;



  @JsonKey(
    
    name: r'expiresInSec',
    required: true,
    includeIfNull: false,
  )


  final int expiresInSec;



  @JsonKey(
    
    name: r'user',
    required: true,
    includeIfNull: false,
  )


  final MeResponse user;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TokensResponse &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.expiresInSec == expiresInSec &&
      other.user == user;

    @override
    int get hashCode =>
        accessToken.hashCode +
        refreshToken.hashCode +
        expiresInSec.hashCode +
        user.hashCode;

  factory TokensResponse.fromJson(Map<String, dynamic> json) => _$TokensResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokensResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

