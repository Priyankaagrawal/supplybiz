//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'khata_account.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KhataAccount {
  /// Returns a new [KhataAccount] instance.
  KhataAccount({
    required this.id,
    required this.kind,
    required this.name,
    required this.balancePaise,
    required this.status,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'kind',
    required: true,
    includeIfNull: false,
  )
  final KhataAccountKindEnum kind;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  /// Customer perspective: positive receivable, negative payable.
  @JsonKey(
    name: r'balancePaise',
    required: true,
    includeIfNull: false,
  )
  final String balancePaise;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final KhataAccountStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhataAccount &&
          other.id == id &&
          other.kind == kind &&
          other.name == name &&
          other.balancePaise == balancePaise &&
          other.status == status;

  @override
  int get hashCode =>
      id.hashCode +
      kind.hashCode +
      name.hashCode +
      balancePaise.hashCode +
      status.hashCode;

  factory KhataAccount.fromJson(Map<String, dynamic> json) =>
      _$KhataAccountFromJson(json);

  Map<String, dynamic> toJson() => _$KhataAccountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum KhataAccountKindEnum {
  @JsonValue(r'VENDOR')
  VENDOR(r'VENDOR'),
  @JsonValue(r'PERSONAL')
  PERSONAL(r'PERSONAL');

  const KhataAccountKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum KhataAccountStatusEnum {
  @JsonValue(r'RECEIVABLE')
  RECEIVABLE(r'RECEIVABLE'),
  @JsonValue(r'PAYABLE')
  PAYABLE(r'PAYABLE'),
  @JsonValue(r'SETTLED')
  SETTLED(r'SETTLED');

  const KhataAccountStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
