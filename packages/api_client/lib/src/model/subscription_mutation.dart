//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_mutation.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionMutation {
  /// Returns a new [SubscriptionMutation] instance.
  SubscriptionMutation({
    required this.id,
    required this.version,
    required this.status,
    required this.effectiveFrom,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'effectiveFrom',
    required: true,
    includeIfNull: false,
  )
  final DateTime effectiveFrom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionMutation &&
          other.id == id &&
          other.version == version &&
          other.status == status &&
          other.effectiveFrom == effectiveFrom;

  @override
  int get hashCode =>
      id.hashCode + version.hashCode + status.hashCode + effectiveFrom.hashCode;

  factory SubscriptionMutation.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionMutationFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionMutationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
