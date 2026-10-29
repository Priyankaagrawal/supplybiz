//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'role_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RoleDto {
  /// Returns a new [RoleDto] instance.
  RoleDto({

    required  this.role,
  });

  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final RoleDtoRoleEnum role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RoleDto &&
      other.role == role;

    @override
    int get hashCode =>
        role.hashCode;

  factory RoleDto.fromJson(Map<String, dynamic> json) => _$RoleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RoleDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum RoleDtoRoleEnum {
@JsonValue(r'CUSTOMER')
CUSTOMER(r'CUSTOMER'),
@JsonValue(r'VENDOR')
VENDOR(r'VENDOR');

const RoleDtoRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


