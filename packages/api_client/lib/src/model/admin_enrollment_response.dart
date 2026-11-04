//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'admin_enrollment_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminEnrollmentResponse {
  /// Returns a new [AdminEnrollmentResponse] instance.
  AdminEnrollmentResponse({
    required this.enrollmentSecret,
  });

  @JsonKey(
    name: r'enrollmentSecret',
    required: true,
    includeIfNull: true,
  )
  final String? enrollmentSecret;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminEnrollmentResponse &&
          other.enrollmentSecret == enrollmentSecret;

  @override
  int get hashCode =>
      (enrollmentSecret == null ? 0 : enrollmentSecret.hashCode);

  factory AdminEnrollmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminEnrollmentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminEnrollmentResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
