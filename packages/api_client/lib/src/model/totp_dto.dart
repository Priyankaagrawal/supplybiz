//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'totp_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TotpDto {
  /// Returns a new [TotpDto] instance.
  TotpDto({
    required this.challengeToken,
    required this.code,
  });

  @JsonKey(
    name: r'challengeToken',
    required: true,
    includeIfNull: false,
  )
  final String challengeToken;

  @JsonKey(
    name: r'code',
    required: true,
    includeIfNull: false,
  )
  final String code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TotpDto &&
          other.challengeToken == challengeToken &&
          other.code == code;

  @override
  int get hashCode => challengeToken.hashCode + code.hashCode;

  factory TotpDto.fromJson(Map<String, dynamic> json) =>
      _$TotpDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TotpDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
