//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'notification_mutation_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NotificationMutationResponse {
  /// Returns a new [NotificationMutationResponse] instance.
  NotificationMutationResponse({
    required this.changed,
  });

  @JsonKey(
    name: r'changed',
    required: true,
    includeIfNull: false,
  )
  final int changed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationMutationResponse && other.changed == changed;

  @override
  int get hashCode => changed.hashCode;

  factory NotificationMutationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationMutationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationMutationResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
