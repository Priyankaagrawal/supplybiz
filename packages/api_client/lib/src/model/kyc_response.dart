//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'kyc_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KycResponse {
  /// Returns a new [KycResponse] instance.
  KycResponse({
    required this.id,
    required this.vendorId,
    required this.status,
    required this.verificationMethod,
    required this.providerChecks,
    required this.submittedAt,
    required this.reviewedAt,
    required this.reviewerId,
    required this.reason,
    required this.aadhaarFrontMediaId,
    required this.aadhaarBackMediaId,
    required this.panMediaId,
    required this.panLast4,
    required this.accountLast4,
    required this.holderName,
    required this.bankName,
    required this.ifsc,
    required this.upiId,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'verificationMethod',
    required: true,
    includeIfNull: false,
  )
  final String verificationMethod;

  @JsonKey(
    name: r'providerChecks',
    required: true,
    includeIfNull: false,
  )
  final KycResponseProviderChecksEnum providerChecks;

  @JsonKey(
    name: r'submittedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime submittedAt;

  @JsonKey(
    name: r'reviewedAt',
    required: true,
    includeIfNull: true,
  )
  final DateTime? reviewedAt;

  @JsonKey(
    name: r'reviewerId',
    required: true,
    includeIfNull: true,
  )
  final String? reviewerId;

  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: true,
  )
  final String? reason;

  @JsonKey(
    name: r'aadhaarFrontMediaId',
    required: true,
    includeIfNull: false,
  )
  final String aadhaarFrontMediaId;

  @JsonKey(
    name: r'aadhaarBackMediaId',
    required: true,
    includeIfNull: false,
  )
  final String aadhaarBackMediaId;

  @JsonKey(
    name: r'panMediaId',
    required: true,
    includeIfNull: false,
  )
  final String panMediaId;

  @JsonKey(
    name: r'panLast4',
    required: true,
    includeIfNull: false,
  )
  final String panLast4;

  @JsonKey(
    name: r'accountLast4',
    required: true,
    includeIfNull: false,
  )
  final String accountLast4;

  @JsonKey(
    name: r'holderName',
    required: true,
    includeIfNull: false,
  )
  final String holderName;

  @JsonKey(
    name: r'bankName',
    required: true,
    includeIfNull: false,
  )
  final String bankName;

  @JsonKey(
    name: r'ifsc',
    required: true,
    includeIfNull: false,
  )
  final String ifsc;

  @JsonKey(
    name: r'upiId',
    required: true,
    includeIfNull: true,
  )
  final String? upiId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KycResponse &&
          other.id == id &&
          other.vendorId == vendorId &&
          other.status == status &&
          other.verificationMethod == verificationMethod &&
          other.providerChecks == providerChecks &&
          other.submittedAt == submittedAt &&
          other.reviewedAt == reviewedAt &&
          other.reviewerId == reviewerId &&
          other.reason == reason &&
          other.aadhaarFrontMediaId == aadhaarFrontMediaId &&
          other.aadhaarBackMediaId == aadhaarBackMediaId &&
          other.panMediaId == panMediaId &&
          other.panLast4 == panLast4 &&
          other.accountLast4 == accountLast4 &&
          other.holderName == holderName &&
          other.bankName == bankName &&
          other.ifsc == ifsc &&
          other.upiId == upiId;

  @override
  int get hashCode =>
      id.hashCode +
      vendorId.hashCode +
      status.hashCode +
      verificationMethod.hashCode +
      providerChecks.hashCode +
      submittedAt.hashCode +
      (reviewedAt == null ? 0 : reviewedAt.hashCode) +
      (reviewerId == null ? 0 : reviewerId.hashCode) +
      (reason == null ? 0 : reason.hashCode) +
      aadhaarFrontMediaId.hashCode +
      aadhaarBackMediaId.hashCode +
      panMediaId.hashCode +
      panLast4.hashCode +
      accountLast4.hashCode +
      holderName.hashCode +
      bankName.hashCode +
      ifsc.hashCode +
      (upiId == null ? 0 : upiId.hashCode);

  factory KycResponse.fromJson(Map<String, dynamic> json) =>
      _$KycResponseFromJson(json);

  Map<String, dynamic> toJson() => _$KycResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum KycResponseProviderChecksEnum {
  @JsonValue(r'NOT_RUN')
  NOT_RUN(r'NOT_RUN');

  const KycResponseProviderChecksEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
