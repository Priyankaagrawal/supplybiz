//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'ledger_adjustment_ack.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LedgerAdjustmentAck {
  /// Returns a new [LedgerAdjustmentAck] instance.
  LedgerAdjustmentAck({
    required this.id,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LedgerAdjustmentAck && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory LedgerAdjustmentAck.fromJson(Map<String, dynamic> json) =>
      _$LedgerAdjustmentAckFromJson(json);

  Map<String, dynamic> toJson() => _$LedgerAdjustmentAckToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
