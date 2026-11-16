//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_revision.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionRevision {
  /// Returns a new [SubscriptionRevision] instance.
  SubscriptionRevision({
    required this.version,
    required this.effectiveFrom,
    required this.qty,
    required this.weekdays,
    required this.timeSlot,
    required this.status,
    required this.action,
    required this.reason,
  });

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'effectiveFrom',
    required: true,
    includeIfNull: false,
  )
  final DateTime effectiveFrom;

  @JsonKey(
    name: r'qty',
    required: true,
    includeIfNull: false,
  )
  final int qty;

  @JsonKey(
    name: r'weekdays',
    required: true,
    includeIfNull: false,
  )
  final List<num> weekdays;

  @JsonKey(
    name: r'timeSlot',
    required: true,
    includeIfNull: false,
  )
  final String timeSlot;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'action',
    required: true,
    includeIfNull: false,
  )
  final String action;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: true,
  )
  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionRevision &&
          other.version == version &&
          other.effectiveFrom == effectiveFrom &&
          other.qty == qty &&
          other.weekdays == weekdays &&
          other.timeSlot == timeSlot &&
          other.status == status &&
          other.action == action &&
          other.reason == reason;

  @override
  int get hashCode =>
      version.hashCode +
      effectiveFrom.hashCode +
      qty.hashCode +
      weekdays.hashCode +
      timeSlot.hashCode +
      status.hashCode +
      action.hashCode +
      (reason == null ? 0 : reason.hashCode);

  factory SubscriptionRevision.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionRevisionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionRevisionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
