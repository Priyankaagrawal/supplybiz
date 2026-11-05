//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'kyc_notice.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KycNotice {
  /// Returns a new [KycNotice] instance.
  KycNotice({
    required this.id,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: true,
  )
  final String? reason;

  @JsonKey(
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KycNotice &&
          other.id == id &&
          other.status == status &&
          other.reason == reason &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      status.hashCode +
      (reason == null ? 0 : reason.hashCode) +
      createdAt.hashCode;

  factory KycNotice.fromJson(Map<String, dynamic> json) =>
      _$KycNoticeFromJson(json);

  Map<String, dynamic> toJson() => _$KycNoticeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
