//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'ledger_reversal_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LedgerReversalInput {
  /// Returns a new [LedgerReversalInput] instance.
  LedgerReversalInput({
    required this.reason,
  });

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerReversalInput && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  factory LedgerReversalInput.fromJson(Map<String, dynamic> json) =>
      _$LedgerReversalInputFromJson(json);

  Map<String, dynamic> toJson() => _$LedgerReversalInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
