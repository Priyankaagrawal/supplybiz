//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'subscription_pause_record.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionPauseRecord {
  /// Returns a new [SubscriptionPauseRecord] instance.
  SubscriptionPauseRecord({
    required this.fromDate,
    required this.toDate,
    required this.resumedFrom,
  });

  @JsonKey(
    name: r'fromDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime fromDate;

  @JsonKey(
    name: r'toDate',
    required: true,
    includeIfNull: true,
  )
  final DateTime? toDate;

  @JsonKey(
    name: r'resumedFrom',
    required: true,
    includeIfNull: true,
  )
  final DateTime? resumedFrom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPauseRecord &&
          other.fromDate == fromDate &&
          other.toDate == toDate &&
          other.resumedFrom == resumedFrom;

  @override
  int get hashCode =>
      fromDate.hashCode +
      (toDate == null ? 0 : toDate.hashCode) +
      (resumedFrom == null ? 0 : resumedFrom.hashCode);

  factory SubscriptionPauseRecord.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPauseRecordFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPauseRecordToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
