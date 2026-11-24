//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'confirm_deletion_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConfirmDeletionInput {
  /// Returns a new [ConfirmDeletionInput] instance.
  ConfirmDeletionInput({
    required this.code,
    required this.acknowledgeReceivables,
  });

  @JsonKey(
    name: r'code',
    required: true,
    includeIfNull: false,
  )
  final String code;

  @JsonKey(
    name: r'acknowledgeReceivables',
    required: true,
    includeIfNull: false,
  )
  final bool acknowledgeReceivables;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfirmDeletionInput &&
          other.code == code &&
          other.acknowledgeReceivables == acknowledgeReceivables;

  @override
  int get hashCode => code.hashCode + acknowledgeReceivables.hashCode;

  factory ConfirmDeletionInput.fromJson(Map<String, dynamic> json) =>
      _$ConfirmDeletionInputFromJson(json);

  Map<String, dynamic> toJson() => _$ConfirmDeletionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
