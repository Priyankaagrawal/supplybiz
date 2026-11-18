//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'ledger_opening_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LedgerOpeningInput {
  /// Returns a new [LedgerOpeningInput] instance.
  LedgerOpeningInput({
    required this.type,
    required this.amountPaise,
    required this.note,
  });

  @JsonKey(
    name: r'type',
    required: true,
    includeIfNull: false,
  )
  final LedgerOpeningInputTypeEnum type;

  @JsonKey(
    name: r'amountPaise',
    required: true,
    includeIfNull: false,
  )
  final String amountPaise;

  @JsonKey(
    name: r'note',
    required: true,
    includeIfNull: false,
  )
  final String note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerOpeningInput &&
          other.type == type &&
          other.amountPaise == amountPaise &&
          other.note == note;

  @override
  int get hashCode => type.hashCode + amountPaise.hashCode + note.hashCode;

  factory LedgerOpeningInput.fromJson(Map<String, dynamic> json) =>
      _$LedgerOpeningInputFromJson(json);

  Map<String, dynamic> toJson() => _$LedgerOpeningInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum LedgerOpeningInputTypeEnum {
  @JsonValue(r'DEBIT')
  DEBIT(r'DEBIT'),
  @JsonValue(r'CREDIT')
  CREDIT(r'CREDIT');

  const LedgerOpeningInputTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
