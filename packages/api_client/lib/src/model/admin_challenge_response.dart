//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'admin_challenge_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminChallengeResponse {
  /// Returns a new [AdminChallengeResponse] instance.
  AdminChallengeResponse({
    required this.challengeToken,
  });

  @JsonKey(
    name: r'challengeToken',
    required: true,
    includeIfNull: false,
  )
  final String challengeToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminChallengeResponse && other.challengeToken == challengeToken;

  @override
  int get hashCode => challengeToken.hashCode;

  factory AdminChallengeResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminChallengeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminChallengeResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
