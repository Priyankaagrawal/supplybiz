//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'me_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeResponse {
  /// Returns a new [MeResponse] instance.
  MeResponse({

    required  this.id,

    required  this.mobile,

    required  this.name,

    required  this.language,

    required  this.roles,

    required  this.activeRole,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'mobile',
    required: true,
    includeIfNull: false,
  )


  final String mobile;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: true,
  )


  final String? name;



  @JsonKey(
    
    name: r'language',
    required: true,
    includeIfNull: false,
  )


  final MeResponseLanguageEnum language;



  @JsonKey(
    
    name: r'roles',
    required: true,
    includeIfNull: false,
  )


  final List<MeResponseRolesEnum> roles;



  @JsonKey(
    
    name: r'activeRole',
    required: true,
    includeIfNull: true,
  )


  final MeResponseActiveRoleEnum? activeRole;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MeResponse &&
      other.id == id &&
      other.mobile == mobile &&
      other.name == name &&
      other.language == language &&
      other.roles == roles &&
      other.activeRole == activeRole;

    @override
    int get hashCode =>
        id.hashCode +
        mobile.hashCode +
        (name == null ? 0 : name.hashCode) +
        language.hashCode +
        roles.hashCode +
        (activeRole == null ? 0 : activeRole.hashCode);

  factory MeResponse.fromJson(Map<String, dynamic> json) => _$MeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MeResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum MeResponseLanguageEnum {
@JsonValue(r'EN')
EN(r'EN'),
@JsonValue(r'HI')
HI(r'HI');

const MeResponseLanguageEnum(this.value);

final String value;

@override
String toString() => value;
}


enum MeResponseRolesEnum {
@JsonValue(r'CUSTOMER')
CUSTOMER(r'CUSTOMER'),
@JsonValue(r'VENDOR')
VENDOR(r'VENDOR');

const MeResponseRolesEnum(this.value);

final String value;

@override
String toString() => value;
}


enum MeResponseActiveRoleEnum {
@JsonValue(r'CUSTOMER')
CUSTOMER(r'CUSTOMER'),
@JsonValue(r'VENDOR')
VENDOR(r'VENDOR');

const MeResponseActiveRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


