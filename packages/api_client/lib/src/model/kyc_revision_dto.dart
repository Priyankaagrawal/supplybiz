//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'kyc_revision_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KycRevisionDto {
  /// Returns a new [KycRevisionDto] instance.
  KycRevisionDto({
    required this.aadhaarFrontMediaId,
    required this.aadhaarBackMediaId,
    required this.panMediaId,
    required this.pan,
    required this.holderName,
    required this.bankName,
    required this.accountNumber,
    required this.accountNumberConfirmation,
    required this.ifsc,
    this.upiId,
    required this.expectedSubmissionId,
  });

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
    name: r'pan',
    required: true,
    includeIfNull: false,
  )
  final String pan;

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
    name: r'accountNumber',
    required: true,
    includeIfNull: false,
  )
  final String accountNumber;

  @JsonKey(
    name: r'accountNumberConfirmation',
    required: true,
    includeIfNull: false,
  )
  final String accountNumberConfirmation;

  @JsonKey(
    name: r'ifsc',
    required: true,
    includeIfNull: false,
  )
  final String ifsc;

  @JsonKey(
    name: r'upiId',
    required: false,
    includeIfNull: false,
  )
  final String? upiId;

  @JsonKey(
    name: r'expectedSubmissionId',
    required: true,
    includeIfNull: false,
  )
  final String expectedSubmissionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KycRevisionDto &&
          other.aadhaarFrontMediaId == aadhaarFrontMediaId &&
          other.aadhaarBackMediaId == aadhaarBackMediaId &&
          other.panMediaId == panMediaId &&
          other.pan == pan &&
          other.holderName == holderName &&
          other.bankName == bankName &&
          other.accountNumber == accountNumber &&
          other.accountNumberConfirmation == accountNumberConfirmation &&
          other.ifsc == ifsc &&
          other.upiId == upiId &&
          other.expectedSubmissionId == expectedSubmissionId;

  @override
  int get hashCode =>
      aadhaarFrontMediaId.hashCode +
      aadhaarBackMediaId.hashCode +
      panMediaId.hashCode +
      pan.hashCode +
      holderName.hashCode +
      bankName.hashCode +
      accountNumber.hashCode +
      accountNumberConfirmation.hashCode +
      ifsc.hashCode +
      upiId.hashCode +
      expectedSubmissionId.hashCode;

  factory KycRevisionDto.fromJson(Map<String, dynamic> json) =>
      _$KycRevisionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$KycRevisionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
