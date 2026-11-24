//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'deletion_receipt.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletionReceipt {
  /// Returns a new [DeletionReceipt] instance.
  DeletionReceipt({
    required this.requestId,
    required this.requestedAt,
    required this.eraseBy,
    required this.status,
  });

  @JsonKey(
    name: r'requestId',
    required: true,
    includeIfNull: false,
  )
  final String requestId;

  @JsonKey(
    name: r'requestedAt',
    required: true,
    includeIfNull: false,
  )
  final String requestedAt;

  @JsonKey(
    name: r'eraseBy',
    required: true,
    includeIfNull: false,
  )
  final String eraseBy;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletionReceipt &&
          other.requestId == requestId &&
          other.requestedAt == requestedAt &&
          other.eraseBy == eraseBy &&
          other.status == status;

  @override
  int get hashCode =>
      requestId.hashCode +
      requestedAt.hashCode +
      eraseBy.hashCode +
      status.hashCode;

  factory DeletionReceipt.fromJson(Map<String, dynamic> json) =>
      _$DeletionReceiptFromJson(json);

  Map<String, dynamic> toJson() => _$DeletionReceiptToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
